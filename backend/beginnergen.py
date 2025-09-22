import random, re

_SAFE_SUBJECTS = [
    "Liam",
    "Noah",
    "Oliver",
    "Elijah",
    "James",
    "William",
    "Benjamin",
    "Lucas",
    "Henry",
    "Alexander",
    "Daniel",
    "Michael",
    "Ethan",
    "Jacob",
    "Logan",
    "Jackson",
    "Aiden",
    "Matthew",
    "Leo",
    "Sebastian",
    "Olivia",
    "Emma",
    "Ava",
    "Sophia",
    "Isabella",
    "Mia",
    "Amelia",
    "Harper",
    "Evelyn",
    "Abigail",
    "Emily",
    "Ella",
    "Elizabeth",
    "Camila",
    "Luna",
    "Sofia",
    "Avery",
    "Mila",
    "Aria",
    "Scarlett",
    "Alex",
    "Taylor",
    "Jordan",
    "Casey",
    "Riley",
    "Morgan",
    "Quinn",
    "Skyler",
    "Rowan",
    "Hayden",
    "Reese",
    "Dakota",
    "Finley",
    "Jamie",
    "Kai",
    "River",
    "Sage",
    "Charlie",
    "Emerson",
    "The father",
    "The mother",
    "The parent",
    "The son",
    "The daughter",
    "The child",
    "The cousin",
    "The aunt",
    "The uncle",
    "The niece",
    "The nephew",
    "The sibling",
    "The grandparent",
    "The grandfather",
    "The grandmother",
    "The parents",
    "The children",
    "The cousins",
    "The siblings",
    "The grandparents",
    "The teacher",
    "The student",
    "The engineer",
    "The doctor",
    "The nurse",
    "The driver",
    "The artist",
    "The chef",
    "The baker",
    "The farmer",
    "The carpenter",
    "The plumber",
    "The electrician",
    "The designer",
    "The writer",
    "The singer",
    "The dancer",
    "The firefighter",
    "The police officer",
    "The developer",
    "The scientist",
    "The pilot",
    "The waiter",
    "The cashier",
    "The coach",
    "The teachers",
    "The students",
    "The engineers",
    "The doctors",
    "The nurses",
    "The drivers",
    "The artists",
    "The chefs",
    "The bakers",
    "The farmers",
    "The carpenters",
    "The plumbers",
    "The electricians",
    "The designers",
    "The writers",
    "The singers",
    "The dancers",
    "The firefighters",
    "The police officers",
    "The developers",
    "The scientists",
    "The pilots",
    "The waiters",
    "The cashiers",
    "The coaches",
    "The cat",
    "The dog",
    "The bird",
    "The rabbit",
    "The horse",
    "The cow",
    "The sheep",
    "The duck",
    "The turtle",
    "The fox",
    "The lion",
    "The tiger",
    "The bear",
    "The panda",
    "The dolphin",
    "The whale",
    "The cats",
    "The dogs",
    "The birds",
    "The rabbits",
    "The horses",
    "The cows",
    "The sheep",
    "The ducks",
    "The turtles",
    "The foxes",
    "The lions",
    "The tigers",
    "The bears",
    "The pandas",
    "The dolphins",
    "The whales",
]

_SAFE_ADVERBS  = ["", "", "", "today", "now", "slowly", "quickly", "carefully", "together"]

_OBJ = {
    "food_eat":   ["bread","rice","an apple","a sandwich","dinner","lunch","breakfast","a meal"],
    "food_drink": ["water","coffee","tea","milk","juice","soup"],
    "food_cook":  ["dinner","rice","a meal","soup","eggs"],

    "thing_open":  ["the door","the window","a box","a bag","a book"],
    "thing_close": ["the door","the window","a box","a bag","a book"],
    "thing_use":   ["a phone","a computer","a pen","a chair","a light"],

    "reading": ["a book","the news","a story","a text message"],
    "media":   ["a movie","a video","music","a song"],

    "place":  ["home","school","work","the store","the park","the room","the kitchen","the bus stop"],
    "person": ["a friend","my friend","the teacher","the doctor","the family","my family"],
    "task":   ["homework","a message","a note","a call"],

    "vehicle": ["a car","the car"]
}

_COMPAT = {
    "eat":       ["food_eat"],
    "drink":     ["food_drink"],
    "cook":      ["food_cook"],
    "make":      ["food_cook","task","thing_use"],
    "have":      ["food_eat","food_drink","a rest","a break","a shower"],
    "get":       ["thing_use","food_eat","task"],
    "buy":       ["thing_use","food_eat"],
    "bring":     ["thing_use","food_eat"],
    "open":      ["thing_open"],
    "close":     ["thing_close"],
    "use":       ["thing_use"],
    "read":      ["reading"],            
    "watch":     ["media"],              
    "play":      ["media","a game"],     
    "listen to": ["media"],              
    "write":     ["task","a note"],      
    "send":      ["task"],               
    "call":      ["person"],
    "help":      ["person"],
    "meet":      ["person"],
    "visit":     ["person","place"],
    "clean":     ["thing_use","place","the room","the kitchen"],
    "find":      ["thing_use"],
    "need":      ["thing_use","food_eat","help"],
    "like":      ["thing_use","food_eat","media","place"],
    "love":      ["thing_use","food_eat","media","place","my family"],
    "go to":     ["place"],
    "come to":   ["place"],
    "walk to":   ["place"],
    "study":     ["English","math","science"],
    "work":      [""],    
    "sleep":     [""],    
    "drive":     ["vehicle"],
}

_FIXES = {
    "a rest":"a rest",
    "a break":"a break",
    "a shower":"a shower",
    "a note":"a note",
    "a game":"a game",
    "help":"help",
    "my family":"my family",
    "English":"English",
    "math":"math",
    "science":"science",
    "": "",
}

def _choose_object_for(verb, rng):
    pools = _COMPAT.get(verb, ["thing"])
    choice = rng.choice(pools)
    if choice in _FIXES:
        return _FIXES[choice]
    lst = _OBJ.get(choice, [])
    return rng.choice(lst) if lst else ""

def _cap(s): 
    return s[:1].upper() + s[1:] if s else s

def generate_sentence_beginner(seed=None):
    rng = random.Random(seed)
    verbs = ["eat","drink","cook","make","have","get","buy","bring","open","close",
             "use","read","watch","play","listen to","write","send","call","help",
             "meet","visit","clean","find","need","like","love","go to","come to",
             "walk to","study","work","sleep","drive"]

    sents = []
    subj = rng.choice(_SAFE_SUBJECTS)
    vb   = rng.choice(verbs)
    adv  = rng.choice(_SAFE_ADVERBS)
    obj = _choose_object_for(vb, rng)
    if obj:
        vp = f"can {vb} {obj}".strip()
    else:
        vp = f"can {vb}".strip()
    if adv:
        if adv in {"today","now"}:
            vp = f"{vp} {adv}"
        else:
            if " can " in f" {vp} ":
                vp = vp.replace("can ", f"can {adv} ", 1)
            else:
                vp = f"{vp} {adv}"
    vp = re.sub(r"\s+", " ", vp).strip()
    vp = vp.replace(" to the home", " home").replace(" to home", " home")
    sent = f"{_cap(subj)} {vp}."
    return sent
