from __future__ import annotations
from dataclasses import dataclass
from typing import Callable
import re
from unicodedata import normalize
from phonemizer import phonemize
from phonemizer.separator import Separator
from pypinyin import lazy_pinyin, Style
from unicodedata import normalize
from g2pk2 import G2p
from hangul_romanize import Transliter
from hangul_romanize.rule import academic
from fugashi import Tagger # type: ignore
import epitran
import jieba
from pykakasi import kakasi

LANG_MAP = {
    'es': 'es',
    'en': 'en-us',
}

_g2p_ko = G2p()
_epi_ko = epitran.Epitran('kor-Hang')
_ko_trans = Transliter(academic)

kks = kakasi()

_JA_PUNCT = re.compile(r'^[\u3000-\u303F。、・「」『』（）\[\]{}…—\-\.\,\!\?]+$')

_CJK_PUNCT = _JA_PUNCT
    
_ja_tagger = Tagger()

_WORD_RE = re.compile(r'[A-Za-z\u00C0-\u024F\u3040-\u30FF\u4E00-\u9FFF\uAC00-\uD7AF0-9]')

def kata_to_hira(s: str) -> str:
    out = []
    for ch in s or "":
        o = ord(ch)
        out.append(chr(o - 0x60) if 0x30A1 <= o <= 0x30F6 else ch)
    return "".join(out)

def _is_word_token_py(tok: str) -> bool:
    return bool(tok) and bool(_WORD_RE.search(tok))

def _tokenize_words(s: str) -> list[str]:
    s = (s or '').strip()
    if not s:
        return []
    return [w for w in re.split(r'\s+', s) if w]

def _align_per_word(
    orig_words: list[str],
    values: list[str],
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

    orig_words = [t for t in (sentence.split()) if _is_word_token_py(t)]

    if not orig_words:
        return Pronunciation(roman=[], ipa=[])

    roman: list[str] = []
    ipa: list[str] = []

    if base in ('ja', 'jpx'):
        try:
            rom_tokens = romanize_ja_tokens(sentence) or []
        except Exception:
            rom_tokens = []

        rom_full = ' '.join(rom_tokens).strip() if rom_tokens else ''

        ipa_tokens = [''] * len(orig_words)
        ipa_full = ''

        rom_tokens = _align_per_word(
            orig_words,
            rom_tokens,
            per_word_fallback=lambda w: ' '.join(romanize_ja_tokens(w) or [])
        )
        return Pronunciation(roman=rom_tokens, ipa=ipa_tokens)

    if base.startswith('zh'):
        try:
            rom_tokens = romanize_zh_tokens(sentence) or []
        except Exception:
            rom_tokens = []

        rom_full = ' '.join(rom_tokens).strip() if rom_tokens else ''
        ipa_tokens = [''] * len(orig_words)
        ipa_full = ''

        rom_tokens = _align_per_word(
            orig_words,
            rom_tokens,
            per_word_fallback=lambda w: ' '.join(romanize_zh_tokens(w) or [])
        )
        return Pronunciation(roman=rom_tokens, ipa=ipa_tokens)

    if base in ('ko', 'kor', 'kor-hang'):
        try:
            pron_hangul_full = _g2p_ko(sentence)                 # str
            ipa_full = (_epi_ko.transliterate(pron_hangul_full) or '').strip()

            try:
                rom_full = (_ko_trans.translit(sentence) or '').strip()
            except Exception:
                rom_full = ''

            ipa_words_from_full = _tokenize_words(ipa_full)
            ipa_tokens = _align_per_word(
                orig_words,
                ipa_words_from_full,
                per_word_fallback=lambda w: (_epi_ko.transliterate(_g2p_ko(w)) or '').strip()
            )

            rom_words_from_full = _tokenize_words(rom_full)
            rom_tokens = _align_per_word(
                orig_words,
                rom_words_from_full,
                per_word_fallback=lambda w: (_ko_trans.translit(w) if hasattr(_ko_trans, 'translit') else '').strip()
            )

            return Pronunciation(roman=rom_tokens, ipa=ipa_tokens)
        except Exception:
            pass

    try:
        ipa_tokens = ipa_word(sentence, lang_code) or []
    except Exception:
        ipa_tokens = []

    ipa_tokens = _align_per_word(
        orig_words,
        ipa_tokens,
        per_word_fallback=lambda w: (ipa_word(w, lang_code) or [''])[0] if ipa_word(w, lang_code) else ''
    )
    ipa_full = ' '.join([t for t in ipa_tokens if t]).strip()

    rom_tokens = [''] * len(orig_words)
    rom_full = ''

    return Pronunciation(roman=rom_tokens, ipa=ipa_tokens)

def pron_tokens(sentence: str, lang_code: str) -> list[str]:
    p = pronounce(sentence, lang_code)
    return p.ipa

def ipa_word(sentence: str, lang_code: str) -> list[str]:
    sentence = normalize('NFC', sentence or '')
    base = (lang_code or '').split('-')[0].lower()
    
    if base in ('ja', 'jpx') or base.startswith('zh'):
        return []

    raw = (sentence or '').strip()
    if not raw:
        return []
    
    raw_tokens = raw.split()
    
    word_tokens = [t for t in raw_tokens if _is_word_token_py(t)]
    if not word_tokens:
        return []

    try:
        tokens = [t for t in word_tokens if any(ch.isalnum() for ch in t)]
        if not tokens:
            return []

        out = phonemize(
            tokens,
            language=LANG_MAP.get(base, base) or base,
            backend='espeak',
            strip=True,
            with_stress=True,
            njobs=1,
            punctuation_marks=';:,.!?¡¿—…"«»“”()[]{}<>-\'',
            preserve_punctuation=False,
            separator=Separator(phone=' ', word='|', syllable=''),
        )
    except Exception:
        return []

    ipa_list: list[str] = []
    for item in out:
        s = item if isinstance(item, str) else ' '.join(str(x) for x in item if x)
        ipa_list.append(s.replace('|', '').strip())

    return [w for w in ipa_list if w]

def romanize_ja_tokens(sentence: str) -> list[str]:
    s = (sentence or "").strip()
    if not s:
        return []
    toks = list(_ja_tagger(s))
    out: list[str] = []
    keys = ("reading","pron","pronunciation","yomi","kana","kanaBase","orthBase","orth")
    for w in toks:
        surface = (w.surface or "").strip()
        if not surface:
            continue
        if _JA_PUNCT.match(surface):
            continue
        feat = getattr(w, "feature", None)
        reading = None
        for k in keys:
            v = safe_feat_get(feat, k)
            if v:
                reading = v.strip()
                break
        hira = kata_to_hira(reading or surface)
        romaji = "".join(d.get("hepburn","") for d in kks.convert(hira)).strip()
        out.append(romaji or surface)
    return [" ".join(t.split()) for t in out if t]

def romanize_zh_tokens(sentence: str) -> list[str]:
    s = (sentence or "").strip()
    if not s:
        return []
    toks = list(jieba.cut(s, HMM=True)) if jieba else list(s)
    out: list[str] = []
    for tok in toks:
        t = tok.strip()
        if not t:
            continue
        if _CJK_PUNCT.match(t):
            continue
        if any('\u4e00' <= ch <= '\u9fff' for ch in t):
            p = ' '.join(lazy_pinyin(t, style=Style.TONE)).strip()
            out.append(p or t)
        else:
            out.append(t)
    return [" ".join(t.split()) for t in out if t]

def safe_feat_get(feat, key: str):
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

def space_chinese_for_flutter(text: str) -> str:
    toks = [t for t in jieba.cut(text or "", HMM=True)] # type: ignore
    if not toks: return text or ""
    out = [toks[0]]
    for prev, cur in zip(toks, toks[1:]):
        if _is_word_token(prev) and _is_word_token(cur):
            out.append(" " + cur)
        else:
            out.append(cur)
    return "".join(out)