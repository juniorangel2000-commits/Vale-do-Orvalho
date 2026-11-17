#!/usr/bin/env python3
"""Gera os aldeões trocando as cores da personagem (cabelo, camisa, calça, pele e sapatos).

Saída: arte/gerada/aldeoes/<id>.png — folha com 8 linhas (direções) e 7 colunas
(parado + 6 quadros andando), cada quadro com 128x128.
Rodar da raiz do projeto:  python3 ferramentas/gerar_aldeoes.py
"""
import colorsys
import os
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
ARTE = os.path.join(AQUI, "..", "arte")
DIRECOES = ["south", "north", "east", "west", "south-east", "south-west", "north-east", "north-west"]
CELULA = 128

# cabelo, camisa, calça, sapato, fator de pele
PALETAS = {
    "celeste": ("#c8c0b8", "#c8a8d8", "#8a5a7a", "#5a3a2a", 1.0),
    "bento": ("#2e2a28", "#b0402e", "#5a4a3a", "#3a2a1a", 0.82),
    "rosa": ("#c8462a", "#e8d8a0", "#4a6a3a", "#5a3a1a", 1.0),
    "tiao": ("#6a4a2a", "#e0b85a", "#4a5a8a", "#4a2e1a", 0.8),
    "nonato": ("#eeeeee", "#5a7a9a", "#6a5a4a", "#3a2a1a", 0.9),
    "augusto": ("#6a6a6a", "#4a4a6e", "#2a2a3a", "#1a1a1a", 0.95),
    "lia": ("#e89a3a", "#fafafa", "#c84a3a", "#6a3a1a", 1.02),
    "davi": ("#1e1a18", "#3a8aaa", "#3a4a6a", "#2a2a2a", 0.7),
    "marina": ("#7a4aaa", "#f0e0f0", "#9a5ac8", "#4a2a4a", 1.0),
    "caio": ("#3a2a1a", "#6a6a72", "#3a3a3a", "#2a2a2a", 0.92),
}


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def recolorir(im, paleta):
    cabelo, camisa, calca, sapato, pele = paleta
    alvo = {"cabelo": hexrgb(cabelo), "camisa": hexrgb(camisa), "calca": hexrgb(calca), "sapato": hexrgb(sapato)}
    referencia = {"cabelo": 0.42, "camisa": 0.9, "calca": 0.5, "sapato": 0.35}
    im = im.convert("RGBA")
    bb = im.getbbox()
    if not bb:
        return im
    topo, base = bb[1], bb[3]
    altura = max(base - topo, 1)
    px = im.load()
    w, h = im.size
    for y in range(h):
        faixa = (y - topo) / altura
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            H, S, V = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            parte = None
            if 0.45 <= H <= 0.72 and S > 0.15:
                parte = "calca"
            elif S < 0.2 and V > 0.68:
                parte = "camisa"
            elif (H < 0.13 or H > 0.95) and S > 0.18:
                pele_tom = S < 0.55 and V > 0.62
                if faixa > 0.86 and not pele_tom:
                    parte = "sapato"
                elif pele_tom:
                    nr, ng, nb = r * pele, g * pele, b * pele * (0.95 if pele < 0.9 else 1.0)
                    px[x, y] = (min(int(nr), 255), min(int(ng), 255), min(int(nb), 255), a)
                    continue
                elif faixa < 0.5 and V > 0.12:
                    parte = "cabelo"
            if parte is None:
                continue
            tr, tg, tb = alvo[parte]
            th, ts, tv = colorsys.rgb_to_hsv(tr, tg, tb)
            nv = min(1.0, V * tv / referencia[parte])
            ns = ts if parte != "camisa" else ts * (0.6 + 0.4 * V)
            nr, ng, nb = colorsys.hsv_to_rgb(th, ns, nv)
            px[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), a)
    return im


def main():
    saida = os.path.join(ARTE, "gerada", "aldeoes")
    os.makedirs(saida, exist_ok=True)
    quadros = []
    for d in DIRECOES:
        linha = [Image.open(os.path.join(ARTE, "personagem", "parada", d + ".png"))]
        for i in range(6):
            linha.append(Image.open(os.path.join(ARTE, "personagem", "andar", d, "frame_%03d.png" % i)))
        quadros.append(linha)
    for npc, paleta in PALETAS.items():
        folha = Image.new("RGBA", (CELULA * 7, CELULA * 8), (0, 0, 0, 0))
        for li, linha in enumerate(quadros):
            for ci, q in enumerate(linha):
                novo = recolorir(q, paleta).resize((CELULA, CELULA), Image.LANCZOS)
                folha.paste(novo, (ci * CELULA, li * CELULA))
        folha.save(os.path.join(saida, npc + ".png"), optimize=True)
        print("ok", npc)
    # conferência: todos parados de frente
    conf = Image.new("RGBA", (CELULA * len(PALETAS), CELULA), (90, 120, 80, 255))
    for i, npc in enumerate(PALETAS):
        f = Image.open(os.path.join(saida, npc + ".png")).crop((0, 0, CELULA, CELULA))
        conf.paste(f, (i * CELULA, 0), f)
    os.makedirs(os.path.join(AQUI, "prints"), exist_ok=True)
    conf.save(os.path.join(AQUI, "prints", "aldeoes.png"))


if __name__ == "__main__":
    main()
