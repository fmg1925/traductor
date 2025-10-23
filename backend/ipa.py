from __future__ import annotations
from dataclasses import dataclass
from typing import Callable, Sequence
import re
from phonemizer import phonemize
from phonemizer.separator import Separator
from pypinyin import lazy_pinyin, Style
from unicodedata import normalize
from g2pk2 import G2p
from hangul_romanize import Transliter
from hangul_romanize.rule import academic
from fugashi import Tagger  # type: ignore
import epitran
import jieba
from pykakasi import kakasi
from functools import lru_cache

LANG_MAP = {
    'es': 'es',
    'en': 'en-us',
}

_PUNCT = ';:,.!?¡¿—…"«»“”()[]{}<>-\''
_SEP = Separator(phone=' ', word='|', syllable='')

_g2p_ko = G2p()
_epi_ko = epitran.Epitran('kor-Hang')
_ko_trans = Transliter(academic)
_ja_tagger = Tagger()
kks = kakasi()

_JA_PUNCT = re.compile(r'^[\u3000-\u303F。、・「」『』（）\[\]{}…—\-\.\,\!\?]+$')
_CJK_PUNCT = _JA_PUNCT
_WORD_RE = re.compile(r'[A-Za-z\u00C0-\u024F\u3040-\u30FF\u4E00-\u9FFF\uAC00-\uD7AF0-9]')

_JA_FEAT_KEYS = ("reading","pron","pronunciation","yomi","kana","kanaBase","orthBase","orth")

JIEBA_HMM = False

def kata_to_hira(s: str) -> str:
    out = []
    for ch in s or "":
        o = ord(ch)
        out.append(chr(o - 0x60) if 0x30A1 <= o <= 0x30F6 else ch)
    return "".join(out)

def _is_word_token_py(tok: str) -> bool:
    return bool(tok) and bool(_WORD_RE.search(tok))

def _align_per_word(
    orig_words: Sequence[str],
    values: Sequence[str],
    per_word_fallback: Callable[[str], str]
) -> list[str]:
    if len(values) == len(orig_words):
        return [v.strip() for v in values]
    out: list[str] = []
    for w in orig_words:
        try:
            out.append((per_word_fallback(w) or '').strip())
        except Exception:
            out.append('')
    return out

@dataclass
class Pronunciation:
    roman: list[str]
    ipa: list[str]

def pronounce(sentence: str, lang_code: str) -> Pronunciation:
    sentence = normalize('NFC', sentence or '').strip()
    base = (lang_code or '').split('-')[0].lower()

    if base in ('ja', 'jpx'):
        toks = [w.surface.strip() for w in _ja_tagger(sentence)
                if w.surface and not _JA_PUNCT.match(w.surface)]
        if not toks:
            return Pronunciation(roman=[], ipa=[])
        roman = []
        for w in toks:
            try:
                hira = kata_to_hira(w)
                rom = "".join(d.get("hepburn","") for d in kks.convert(hira)).strip()
            except Exception:
                rom = w
            roman.append(rom or w)
        return Pronunciation(roman=roman, ipa=[''] * len(roman))

    if base.startswith('zh'):
        toks = [t.strip() for t in jieba.cut(sentence, HMM=JIEBA_HMM)
                if t.strip() and not _CJK_PUNCT.match(t)]
        if not toks:
            return Pronunciation(roman=[], ipa=[])
        roman = []
        for w in toks:
            if any('\u4e00' <= ch <= '\u9fff' for ch in w):
                p = ' '.join(lazy_pinyin(w, style=Style.TONE)).strip()
                roman.append(p or w)
            else:
                roman.append(w)
        return Pronunciation(roman=roman, ipa=[''] * len(roman))

    orig_words = [t for t in sentence.split() if _is_word_token_py(t)]
    if not orig_words:
        return Pronunciation(roman=[], ipa=[])

    if base in ('ko', 'kor', 'kor-hang'):
        try:
            pron_hangul_full = _g2p_ko(sentence)
            ipa_full = (_epi_ko.transliterate(pron_hangul_full) or '').strip()
            try:
                rom_full = (_ko_trans.translit(sentence) or '').strip()
            except Exception:
                rom_full = ''
            ipa_tokens = _align_per_word(orig_words, ipa_full.split(),
                per_word_fallback=lambda w: (_epi_ko.transliterate(_g2p_ko(w)) or '').strip())
            rom_tokens = _align_per_word(orig_words, rom_full.split(),
                per_word_fallback=lambda w: _ko_trans.translit(w).strip())
            return Pronunciation(roman=rom_tokens, ipa=ipa_tokens)
        except Exception:
            pass

    try:
        seed = ipa_word(sentence, lang_code) or []
    except Exception:
        seed = []
    _cache = {}
    ipa_tokens = _align_per_word(orig_words, seed,
        per_word_fallback=lambda w: _cache.setdefault(w, (ipa_word(w, lang_code) or [''])[0]))
    return Pronunciation(roman=[''] * len(orig_words), ipa=ipa_tokens)

@lru_cache(maxsize=50000)
def ipa_word(sentence: str, lang_code: str) -> list[str]:
    sentence = normalize('NFC', sentence or '')
    base = (lang_code or '').split('-')[0].lower()

    if base in ('ja', 'jpx') or base.startswith('zh'):
        return []

    raw = (sentence or '').strip()
    if not raw:
        return []

    raw_tokens = raw.split()
    
    sanitized = []
    for t in raw_tokens:
        if not _is_word_token_py(t):
            continue
        t2 = re.sub(r"[’'/_\-]+", "", t)
        t2 = t2.strip()
        if not t2 or not any(ch.isalnum() for ch in t2):
            continue
        sanitized.append(t2)
    
    tokens = sanitized
    if not tokens:
        return []

    primary = LANG_MAP.get(base, base) or base or 'en-us'
    candidates = []
    for c in (primary, base, 'en-us', 'en', 'es'):
        if c and ('mb' not in c.lower()):
            if c not in candidates:
                candidates.append(c)

    out = None
    for lang in candidates:
        try:
            out = phonemize(
                tokens,
                language=lang,
                backend='espeak',
                strip=True,
                with_stress=True,
                njobs=1,
                punctuation_marks=_PUNCT,
                preserve_punctuation=False,
                separator=_SEP,
            )
            break
        except:
            out = None
            continue

    if out is None:
        return []

    if isinstance(out, str):
        out = [out]

    norm_out: list[str] = []
    for o in out:
        if isinstance(o, tuple):
            o = " ".join(s for s in o if isinstance(s, str))
        elif not isinstance(o, str):
            o = str(o)
        o = o.replace('|', '').strip()
        if o:
            norm_out.append(o)

    return norm_out

@lru_cache(maxsize=50000)
def romanize_ja_tokens(sentence: str) -> list[str]:
    s = (sentence or "").strip()
    if not s:
        return []
    toks = list(_ja_tagger(s))
    out: list[str] = []
    for w in toks:
        surface = (w.surface or "").strip()
        if not surface or _JA_PUNCT.match(surface):
            continue
        feat = getattr(w, "feature", None)
        reading = None
        for k in _JA_FEAT_KEYS:
            v = safe_feat_get(feat, k)
            if v:
                reading = v.strip()
                break
        hira = kata_to_hira(reading or surface)
        romaji = "".join(d.get("hepburn","") for d in kks.convert(hira)).strip()
        out.append(romaji or surface)
    return [''.join(t.split()) for t in out if t]

@lru_cache(maxsize=50000)
def romanize_zh_tokens(sentence: str) -> list[str]:
    s = (sentence or "").strip()
    if not s:
        return []
    toks = list(jieba.cut(s, HMM=JIEBA_HMM))
    out: list[str] = []
    for tok in toks:
        t = tok.strip()
        if not t or _CJK_PUNCT.match(t):
            continue
        if any('\u4e00' <= ch <= '\u9fff' for ch in t):
            p = ' '.join(lazy_pinyin(t, style=Style.TONE)).strip()
            out.append(p or t)
        else:
            out.append(t)
    return [" ".join(t.split()) for t in out if t]

def safe_feat_get(feat, key: str) -> None | str:
    if feat is None:
        return None
    if isinstance(feat, dict):
        v = feat.get(key)
    else:
        v = getattr(feat, key, None)
    return (v.strip() if isinstance(v, str) else (str(v).strip() if v is not None else None))

def _is_word_char_u(code: int) -> bool:
    return (
        (0x0041 <= code <= 0x024F) or
        (0x3040 <= code <= 0x30FF) or
        (0x4E00 <= code <= 0x9FFF) or
        (0xAC00 <= code <= 0xD7AF)
    )

def _is_word_token(s: str) -> bool:
    return bool(s) and _is_word_char_u(ord(s[0]))

@lru_cache(maxsize=50000)
def space_japanese_for_flutter(text: str) -> str:
    toks = [w.surface for w in _ja_tagger(text or "")]
    if not toks:
        return text or ""
    out = [toks[0]]
    for prev, cur in zip(toks, toks[1:]):
        if _is_word_token(prev) and _is_word_token(cur):
            out.append(" " + cur)
        else:
            out.append(cur)
    return "".join(out)

@lru_cache(maxsize=50000)
def space_chinese_for_flutter(text: str) -> str:
    toks = [t for t in jieba.cut(text or "", HMM=JIEBA_HMM)]
    if not toks:
        return text or ""
    out = [toks[0]]
    for prev, cur in zip(toks, toks[1:]):
        if _is_word_token(prev) and _is_word_token(cur):
            out.append(" " + cur)
        else:
            out.append(cur)
    return "".join(out)
