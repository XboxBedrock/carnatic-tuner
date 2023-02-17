wee = []
from unidecode import unidecode
import json

with open("l (1).csv", "r", encoding="utf8") as e:
    for i in e.readlines():
        split = i.split(",")
        wee.append(split[:3])
        wee.append(split[3:])

yeee = {}

translate = {
    "S": ["S", 0],
    "Ṡ": ["S", 0],
    "R₁": ["R", 1],
    "R₂": ["R", 2],
    "R₃": ["R", 3],
    "G₁": ["G", 1],
    "G₂": ["G", 2],
    "G₃": ["G", 3],
    "M₁": ["M", 1],
    "M₂": ["M", 2],
    "P": ["P", 0],
    "D₁": ["D", 1],
    "D₂": ["D", 2],
    "D₃": ["D", 3],
    "N₁": ["N", 1],
    "N₂": ["N", 2],
    "N₃": ["N", 3],

}

ragas = []

for i in wee:
    name = unidecode(i[1])
    scale = i[2].replace("\xa0", " ").replace("\n", "")
    scar = []
    for j in scale.split(" "):
        scar.append(translate[j])
    ragas.append(name)
    yeee[name] = scar
export = {"list": ragas, "map": yeee}

with open("ragas.json", "w") as f:
    json.dump(export, f)