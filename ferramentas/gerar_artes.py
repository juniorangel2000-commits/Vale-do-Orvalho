#!/usr/bin/env python3
"""Gera as artes em pixel art do Vale do Orvalho (itens, plantas, objetos, animais, monstros).

Cada sprite é desenhado em baixa resolução (16x16, 16x32...) com formas simples; depois
recebe sombreado (luz de cima à esquerda) e contorno escuro automáticos.
Rodar da raiz do projeto:  python3 ferramentas/gerar_artes.py
Saída: arte/gerada/{itens,culturas,objetos,animais,monstros}/*.png
"""
import os
from PIL import Image, ImageDraw

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "arte", "gerada")


# ------------------------------------------------------------------ cores

def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mix(c, d, t):
    return tuple(int(c[i] + (d[i] - c[i]) * t) for i in range(3)) + (c[3] if len(c) > 3 else 255,)


def claro(c, t=0.35):
    return mix(c, (255, 255, 255, 255), t)


def escuro(c, t=0.35):
    return mix(c, (20, 12, 24, 255), t)


# ------------------------------------------------------------------ base

def tela(w=16, h=16):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def acabar(im, contorno=True, sombra=True):
    """Sombreado simples + contorno de 1 pixel."""
    w, h = im.size
    px = im.load()
    orig = im.copy().load()
    if sombra:
        for y in range(h):
            for x in range(w):
                c = orig[x, y]
                if c[3] == 0 or c[3] == 254:  # 254 = cor que não recebe sombra
                    continue
                cima = orig[x, y - 1][3] if y > 0 else 0
                esq = orig[x - 1, y][3] if x > 0 else 0
                baixo = orig[x, y + 1][3] if y < h - 1 else 0
                dir_ = orig[x + 1, y][3] if x < w - 1 else 0
                if cima == 0 or esq == 0:
                    px[x, y] = claro(c, 0.22)[:3] + (255,)
                elif baixo == 0 or dir_ == 0:
                    px[x, y] = escuro(c, 0.22)[:3] + (255,)
                else:
                    px[x, y] = c[:3] + (255,)
    if contorno:
        base = im.copy().load()
        for y in range(h):
            for x in range(w):
                if base[x, y][3] != 0:
                    continue
                viz = []
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < w and 0 <= yy < h and base[xx, yy][3] != 0:
                        viz.append(base[xx, yy])
                if viz:
                    c = viz[0]
                    px[x, y] = escuro(c, 0.62)[:3] + (255,)
    return im


def salvar(im, pasta, nome):
    d = os.path.join(RAIZ, pasta)
    os.makedirs(d, exist_ok=True)
    im.save(os.path.join(d, nome + ".png"))


def sem_sombra(c):
    return c[:3] + (254,)


# ------------------------------------------------------------------ itens (16x16)

def it_semente(cor):
    im, d = tela()
    d.rectangle((3, 2, 12, 14), fill=hexc("#d9bf86"))
    d.rectangle((3, 2, 12, 4), fill=hexc("#b8995e"))
    d.ellipse((5, 7, 10, 12), fill=cor)
    d.point([(6, 8)], fill=claro(cor, 0.6))
    return acabar(im)


def it_folha(cor):
    im, d = tela()
    d.ellipse((2, 4, 13, 14), fill=escuro(cor, 0.15))
    d.ellipse((3, 3, 11, 11), fill=cor)
    d.ellipse((6, 5, 13, 12), fill=claro(cor, 0.15))
    d.line((7, 13, 7, 6), fill=claro(cor, 0.45))
    d.line((7, 9, 5, 7), fill=claro(cor, 0.45))
    d.line((7, 10, 10, 8), fill=claro(cor, 0.45))
    return acabar(im)


def it_bola(cor, gomos=False):
    im, d = tela()
    d.ellipse((2, 4, 13, 14), fill=cor)
    if gomos:
        d.line((7, 5, 7, 13), fill=escuro(cor, 0.25))
        d.line((4, 6, 4, 12), fill=escuro(cor, 0.2))
        d.line((10, 6, 10, 12), fill=escuro(cor, 0.2))
    d.rectangle((5, 6, 6, 7), fill=sem_sombra(claro(cor, 0.55)))
    d.rectangle((7, 2, 8, 4), fill=hexc("#4a7a2a"))
    d.point([(9, 3), (10, 3)], fill=hexc("#5a9a3a"))
    return acabar(im)


def it_batata(cor):
    im, d = tela()
    d.ellipse((2, 5, 13, 13), fill=cor)
    d.ellipse((4, 4, 11, 11), fill=cor)
    for p in [(5, 8), (9, 7), (8, 11), (11, 10)]:
        d.point([p], fill=escuro(cor, 0.35))
    return acabar(im)


def it_berinjela(cor):
    im, d = tela()
    d.ellipse((4, 4, 12, 15), fill=cor)
    d.ellipse((3, 8, 11, 15), fill=cor)
    d.rectangle((6, 6, 7, 7), fill=sem_sombra(claro(cor, 0.4)))
    d.polygon([(6, 1), (11, 2), (12, 5), (5, 5)], fill=hexc("#4a8a3a"))
    return acabar(im)


def it_raiz(cor, folhas=True):
    im, d = tela()
    d.polygon([(4, 6), (12, 6), (9, 15), (7, 15)], fill=cor)
    d.ellipse((3, 4, 12, 10), fill=cor)
    d.line((6, 9, 8, 9), fill=escuro(cor, 0.25))
    d.line((7, 12, 9, 12), fill=escuro(cor, 0.25))
    if folhas:
        d.line((7, 4, 5, 1), fill=hexc("#5a9a3a"))
        d.line((8, 4, 8, 0), fill=hexc("#6aaa3a"))
        d.line((9, 4, 11, 1), fill=hexc("#5a9a3a"))
    return acabar(im)


def it_alho(cor):
    im, d = tela()
    d.ellipse((3, 6, 12, 14), fill=cor)
    d.polygon([(6, 7), (9, 7), (8, 2), (7, 2)], fill=cor)
    d.line((7, 8, 6, 13), fill=escuro(cor, 0.2))
    d.line((9, 8, 10, 13), fill=escuro(cor, 0.2))
    d.line((7, 2, 6, 0), fill=hexc("#7aaa4a"))
    return acabar(im)


def it_morango(cor):
    im, d = tela()
    d.polygon([(2, 6), (13, 6), (12, 10), (8, 15), (7, 15), (3, 10)], fill=cor)
    d.ellipse((2, 4, 13, 10), fill=cor)
    for p in [(5, 7), (9, 7), (7, 10), (11, 9), (4, 9), (7, 13)]:
        d.point([p], fill=sem_sombra(hexc("#f8e8a0")))
    d.polygon([(4, 4), (7, 2), (8, 1), (9, 2), (12, 4), (8, 5)], fill=hexc("#4a9a3a"))
    return acabar(im)


def it_uva(cor):
    im, d = tela()
    for (x, y) in [(3, 4), (7, 4), (11, 4), (5, 7), (9, 7), (3, 8), (11, 8), (7, 10), (5, 11), (9, 11), (7, 13)]:
        d.ellipse((x - 1, y - 1, x + 2, y + 2), fill=cor)
        d.point([(x, y)], fill=sem_sombra(claro(cor, 0.4)))
    d.line((7, 3, 8, 0), fill=hexc("#6a4a2a"))
    d.point([(9, 1), (10, 1)], fill=hexc("#5a9a3a"))
    return acabar(im)


def it_amora(cor):
    im, d = tela()
    for (x, y) in [(6, 5), (9, 5), (5, 8), (8, 8), (11, 8), (6, 11), (9, 11), (8, 13)]:
        d.ellipse((x - 1, y - 1, x + 1, y + 1), fill=cor)
    d.point([(6, 5), (9, 8)], fill=sem_sombra(claro(cor, 0.5)))
    d.polygon([(6, 3), (8, 1), (10, 3)], fill=hexc("#5a9a3a"))
    return acabar(im)


def it_pimenta(cor):
    im, d = tela()
    d.polygon([(4, 4), (8, 3), (11, 6), (12, 11), (10, 15), (9, 12), (7, 8)], fill=cor)
    d.point([(6, 5), (7, 5)], fill=sem_sombra(claro(cor, 0.5)))
    d.line((4, 4, 2, 2), fill=hexc("#4a8a2a"))
    d.rectangle((3, 3, 5, 5), fill=hexc("#4a8a2a"))
    return acabar(im)


def it_milho(cor):
    im, d = tela()
    d.ellipse((5, 1, 11, 14), fill=cor)
    for y in range(3, 13, 2):
        d.line((6, y, 10, y), fill=escuro(cor, 0.2))
    d.polygon([(3, 15), (5, 6), (8, 14)], fill=hexc("#7aaa4a"))
    d.polygon([(13, 15), (11, 6), (8, 14)], fill=hexc("#6a9a3a"))
    return acabar(im)


def it_melancia(cor):
    im, d = tela()
    d.ellipse((1, 3, 14, 14), fill=cor)
    for x in (4, 7, 10):
        d.line((x, 4, x - 1, 13), fill=escuro(cor, 0.4))
    d.rectangle((4, 5, 5, 6), fill=sem_sombra(claro(cor, 0.5)))
    return acabar(im)


def it_flor(cor, miolo="#e8a82a"):
    im, d = tela()
    d.line((7, 15, 7, 8), fill=hexc("#4a8a2a"))
    d.line((7, 12, 10, 10), fill=hexc("#4a8a2a"))
    d.point([(11, 9)], fill=hexc("#5a9a3a"))
    for (x, y) in [(7, 2), (4, 4), (10, 4), (4, 7), (10, 7), (7, 9)]:
        d.ellipse((x - 2, y - 1, x + 2, y + 2), fill=cor)
    d.ellipse((6, 4, 9, 7), fill=sem_sombra(hexc(miolo)))
    return acabar(im)


def it_girassol(cor):
    im, d = tela()
    d.line((7, 15, 7, 9), fill=hexc("#4a8a2a"))
    d.polygon([(7, 12), (11, 10), (10, 13)], fill=hexc("#5a9a3a"))
    d.ellipse((1, 0, 14, 12), fill=cor)
    d.ellipse((5, 3, 10, 8), fill=sem_sombra(hexc("#5a3a1a")))
    d.point([(6, 4), (8, 6)], fill=sem_sombra(hexc("#7a5a2a")))
    return acabar(im)


def it_cogumelo(cor):
    im, d = tela()
    d.rectangle((6, 8, 9, 14), fill=hexc("#efe4d0"))
    d.pieslice((1, 2, 14, 14), 180, 360, fill=cor)
    d.point([(4, 5), (9, 4), (11, 6)], fill=sem_sombra(claro(cor, 0.55)))
    return acabar(im)


def it_pedra(cor):
    im, d = tela()
    d.polygon([(2, 11), (4, 5), (9, 3), (13, 6), (14, 11), (11, 14), (4, 14)], fill=cor)
    d.line((5, 7, 8, 5), fill=sem_sombra(claro(cor, 0.35)))
    d.point([(10, 10), (6, 11)], fill=escuro(cor, 0.25))
    return acabar(im)


def it_minerio(cor):
    im, d = tela()
    d.polygon([(2, 11), (4, 5), (9, 3), (13, 6), (14, 11), (11, 14), (4, 14)], fill=hexc("#7a726a"))
    for (x, y) in [(5, 7), (9, 6), (8, 10), (11, 11)]:
        d.rectangle((x, y, x + 1, y + 1), fill=sem_sombra(cor))
        d.point([(x, y)], fill=sem_sombra(claro(cor, 0.5)))
    return acabar(im)


def it_barra(cor):
    im, d = tela()
    d.polygon([(1, 13), (4, 6), (12, 6), (15, 13)], fill=cor)
    d.line((4, 7, 12, 7), fill=sem_sombra(claro(cor, 0.55)))
    d.line((5, 9, 10, 9), fill=sem_sombra(claro(cor, 0.3)))
    return acabar(im)


def it_gema(cor):
    im, d = tela()
    d.polygon([(7, 1), (13, 6), (8, 15), (7, 15), (2, 6)], fill=cor)
    d.polygon([(7, 1), (13, 6), (7, 6)], fill=sem_sombra(claro(cor, 0.45)))
    d.polygon([(2, 6), (7, 6), (7, 15)], fill=sem_sombra(escuro(cor, 0.15)))
    d.point([(5, 4)], fill=sem_sombra(hexc("#ffffff")))
    return acabar(im)


def it_tronco(cor):
    im, d = tela()
    d.rectangle((1, 5, 12, 11), fill=cor)
    d.line((2, 7, 10, 7), fill=escuro(cor, 0.2))
    d.ellipse((10, 4, 14, 12), fill=sem_sombra(claro(cor, 0.35)))
    d.ellipse((11, 6, 13, 10), fill=sem_sombra(claro(cor, 0.15)))
    return acabar(im)


def it_fibra(cor):
    im, d = tela()
    for i, x in enumerate(range(4, 13, 2)):
        d.line((x, 14, x - 2 + i % 2 * 2, 2), fill=cor if i % 2 else claro(cor, 0.2))
    d.line((3, 9, 12, 9), fill=hexc("#8a5a2a"))
    return acabar(im, sombra=False)


def it_peixe(cor, tipo="normal"):
    im, d = tela()
    if tipo == "enguia":
        d.line((1, 10, 4, 7), fill=cor, width=3)
        d.line((4, 7, 9, 9), fill=cor, width=3)
        d.line((9, 9, 14, 5), fill=cor, width=3)
        d.point([(13, 5)], fill=sem_sombra(hexc("#000000")))
        return acabar(im)
    d.ellipse((1, 4, 11, 12), fill=cor)
    d.polygon([(10, 8), (15, 3), (15, 13)], fill=escuro(cor, 0.2))
    d.polygon([(4, 4), (7, 2), (8, 5)], fill=escuro(cor, 0.15))
    d.line((3, 9, 8, 9), fill=sem_sombra(claro(cor, 0.45)))
    d.point([(3, 6)], fill=sem_sombra(hexc("#1a1a1a")))
    if tipo == "bagre":
        d.line((1, 8, 0, 11), fill=escuro(cor, 0.4))
        d.line((2, 9, 2, 12), fill=escuro(cor, 0.4))
    if tipo == "pintado":
        for p in [(5, 6), (7, 8), (9, 6), (6, 10)]:
            d.point([p], fill=sem_sombra(escuro(cor, 0.5)))
    if tipo == "brilho":
        for p in [(5, 6), (8, 5), (7, 10)]:
            d.point([p], fill=sem_sombra(hexc("#ffffff")))
    return acabar(im)


def it_ovo(cor):
    im, d = tela()
    d.ellipse((3, 2, 12, 14), fill=cor)
    d.ellipse((2, 6, 13, 14), fill=cor)
    d.rectangle((5, 5, 6, 6), fill=sem_sombra(hexc("#ffffff")))
    return acabar(im)


def it_garrafa(cor, vidro=True):
    im, d = tela()
    d.rectangle((6, 1, 9, 4), fill=hexc("#c8a878"))
    d.rectangle((5, 4, 10, 6), fill=hexc("#d8e8ec") if vidro else cor)
    d.rectangle((3, 6, 12, 14), fill=cor)
    d.rectangle((3, 6, 12, 7), fill=claro(cor, 0.25))
    d.line((5, 8, 5, 12), fill=sem_sombra(claro(cor, 0.6)))
    return acabar(im)


def it_xicara(cor):
    im, d = tela()
    d.rectangle((3, 6, 11, 13), fill=hexc("#f0ece4"))
    d.rectangle((4, 6, 10, 7), fill=sem_sombra(cor))
    d.ellipse((10, 7, 14, 11), outline=hexc("#f0ece4"))
    d.line((1, 14, 13, 14), fill=hexc("#e0d8c8"))
    d.line((6, 4, 7, 1), fill=sem_sombra(hexc("#d8d8d8", 160)))
    d.line((9, 4, 8, 1), fill=sem_sombra(hexc("#d8d8d8", 160)))
    return acabar(im)


def it_pote(cor):
    im, d = tela()
    d.rectangle((3, 2, 12, 4), fill=hexc("#c8a85a"))
    d.rectangle((2, 5, 13, 14), fill=cor)
    d.rectangle((4, 8, 11, 11), fill=sem_sombra(hexc("#f8f0e0")))
    d.line((5, 9, 10, 9), fill=sem_sombra(hexc("#b89870")))
    return acabar(im)


def it_queijo(cor):
    im, d = tela()
    d.polygon([(1, 12), (14, 12), (14, 6), (5, 3)], fill=cor)
    d.rectangle((1, 12, 14, 14), fill=escuro(cor, 0.1))
    for p in [(9, 8), (6, 10), (12, 10)]:
        d.ellipse((p[0] - 1, p[1] - 1, p[0] + 1, p[1]), fill=sem_sombra(escuro(cor, 0.25)))
    return acabar(im)


def it_la(cor):
    im, d = tela()
    for (x, y) in [(5, 6), (10, 6), (3, 10), (8, 10), (12, 10), (7, 4)]:
        d.ellipse((x - 3, y - 3, x + 3, y + 3), fill=cor)
    return acabar(im)


def it_tecido(cor):
    im, d = tela()
    d.polygon([(1, 6), (12, 3), (15, 11), (4, 14)], fill=cor)
    d.line((2, 8, 13, 5), fill=escuro(cor, 0.2))
    d.line((3, 11, 14, 8), fill=escuro(cor, 0.2))
    return acabar(im)


def it_prato(cor, tipo="monte"):
    im, d = tela()
    d.ellipse((0, 7, 15, 15), fill=hexc("#f0f0ea"))
    d.ellipse((2, 8, 13, 13), fill=hexc("#dcdcd2"))
    if tipo == "monte":
        d.ellipse((3, 4, 12, 12), fill=cor)
        d.point([(5, 6), (6, 5)], fill=sem_sombra(claro(cor, 0.5)))
    elif tipo == "sopa":
        d.ellipse((2, 7, 13, 12), fill=cor)
        d.point([(5, 9), (9, 8)], fill=sem_sombra(claro(cor, 0.5)))
    elif tipo == "torta":
        d.pieslice((2, 3, 13, 13), 200, 340, fill=hexc("#e0b878"))
        d.rectangle((3, 8, 12, 11), fill=hexc("#d0a060"))
        d.line((4, 8, 11, 8), fill=sem_sombra(cor))
    elif tipo == "peixe":
        d.ellipse((2, 6, 11, 11), fill=cor)
        d.polygon([(10, 8), (14, 5), (14, 11)], fill=escuro(cor, 0.2))
    return acabar(im)


def it_saco(cor):
    im, d = tela()
    d.polygon([(3, 15), (2, 9), (4, 4), (11, 4), (13, 9), (12, 15)], fill=hexc("#c8a878"))
    d.rectangle((5, 2, 10, 4), fill=hexc("#a88858"))
    d.ellipse((5, 8, 10, 13), fill=sem_sombra(cor))
    return acabar(im)


def it_bota(cor):
    im, d = tela()
    d.polygon([(4, 1), (9, 1), (9, 10), (14, 11), (14, 15), (3, 15)], fill=cor)
    d.line((4, 4, 9, 4), fill=escuro(cor, 0.3))
    return acabar(im)


def it_buque(cor):
    im, d = tela()
    d.polygon([(5, 15), (10, 15), (12, 8), (3, 8)], fill=hexc("#e8dcc0"))
    for (x, y, c) in [(4, 5, cor), (8, 3, "#f8f0a0"), (11, 5, "#e86a6a"), (6, 7, "#a8c8f8"), (10, 8, cor)]:
        cc = hexc(c) if isinstance(c, str) else c
        d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=cc)
    d.line((5, 12, 10, 12), fill=sem_sombra(hexc("#e84a6a")))
    return acabar(im)


def it_anel(cor):
    im, d = tela()
    d.ellipse((3, 5, 12, 14), outline=hexc("#e8c33a"), width=2)
    d.polygon([(7, 1), (10, 3), (7, 6), (5, 3)], fill=cor)
    d.point([(7, 2)], fill=sem_sombra(hexc("#ffffff")))
    return acabar(im)


def it_chave(cor):
    im, d = tela()
    d.ellipse((1, 3, 7, 9), outline=cor, width=2)
    d.rectangle((6, 5, 14, 6), fill=cor)
    d.rectangle((11, 7, 12, 9), fill=cor)
    d.rectangle((13, 7, 14, 8), fill=cor)
    return acabar(im)


def it_muda(cor):
    im, d = tela()
    d.polygon([(4, 15), (11, 15), (10, 11), (5, 11)], fill=hexc("#a86a3a"))
    d.line((7, 11, 7, 5), fill=hexc("#6a4a2a"))
    d.ellipse((3, 2, 9, 7), fill=hexc("#5a9a3a"))
    d.ellipse((7, 1, 13, 6), fill=hexc("#6aaa44"))
    d.ellipse((9, 4, 11, 6), fill=sem_sombra(cor))
    return acabar(im)


def it_bolota(cor):
    im, d = tela()
    d.ellipse((4, 5, 11, 14), fill=cor)
    d.pieslice((3, 2, 12, 9), 180, 360, fill=hexc("#6a4a2a"))
    d.line((7, 2, 8, 0), fill=hexc("#5a3a1a"))
    d.point([(6, 9)], fill=sem_sombra(claro(cor, 0.5)))
    return acabar(im)


def it_isca(cor):
    im, d = tela()
    d.line((3, 12, 6, 9), fill=cor, width=2)
    d.line((6, 9, 10, 10), fill=cor, width=2)
    d.line((10, 10, 13, 6), fill=cor, width=2)
    return acabar(im)


def it_escada(cor):
    im, d = tela()
    d.line((4, 1, 4, 15), fill=cor, width=2)
    d.line((11, 1, 11, 15), fill=cor, width=2)
    for y in (3, 7, 11):
        d.line((5, y, 10, y), fill=claro(cor, 0.2))
    return acabar(im)


# ------------------------------------------------------------------ ferramentas (16x16, 4 níveis)

METAIS = ["#8e8e96", "#c87443", "#d8d8e4", "#e8c33a"]
CABO = "#8a5a2a"


def ferramenta(tipo, nivel):
    im, d = tela()
    m = hexc(METAIS[nivel])
    c = hexc(CABO)
    if tipo == "enxada":
        d.line((2, 14, 10, 6), fill=c, width=2)
        d.polygon([(8, 3), (14, 5), (13, 8), (9, 6)], fill=m)
    elif tipo == "regador":
        d.rectangle((3, 6, 10, 13), fill=m)
        d.line((10, 9, 14, 4), fill=m, width=2)
        d.arc((4, 2, 10, 9), 180, 360, fill=escuro(m, 0.3))
    elif tipo == "machado":
        d.line((3, 15, 10, 4), fill=c, width=2)
        d.polygon([(8, 2), (14, 1), (14, 8), (10, 7)], fill=m)
    elif tipo == "picareta":
        d.line((4, 15, 9, 5), fill=c, width=2)
        d.arc((2, 1, 15, 12), 200, 340, fill=m, width=2)
    elif tipo == "foice":
        d.line((4, 15, 6, 6), fill=c, width=2)
        d.arc((5, 1, 15, 11), 170, 330, fill=m, width=2)
    elif tipo == "vara":
        d.line((2, 15, 14, 1), fill=c)
        d.line((14, 1, 14, 10), fill=sem_sombra(hexc("#e8e8e8", 200)))
        d.ellipse((4, 10, 7, 13), fill=hexc("#3a3a3a"))
    elif tipo == "vara_fibra":
        d.line((2, 15, 14, 1), fill=hexc("#6a9a4a"))
        d.line((14, 1, 14, 10), fill=sem_sombra(hexc("#e8e8e8", 200)))
        d.ellipse((4, 10, 7, 13), fill=hexc("#c8463a"))
    elif tipo in ("espada", "espada_aco"):
        lam = hexc("#e8e8f4") if tipo == "espada_aco" else hexc("#a8a8a8")
        d.line((5, 10, 14, 1), fill=lam, width=2)
        d.line((3, 8, 7, 12), fill=hexc("#a87a2a"), width=2)
        d.line((2, 13, 5, 10), fill=c, width=2)
    elif tipo == "balde":
        d.polygon([(3, 5), (12, 5), (11, 14), (4, 14)], fill=hexc("#a8a8b4"))
        d.arc((3, 0, 12, 10), 180, 360, fill=hexc("#6a6a72"))
        d.rectangle((4, 6, 11, 7), fill=sem_sombra(hexc("#f8f8f8")))
    elif tipo == "tesoura":
        d.line((3, 13, 13, 3), fill=hexc("#c8c8d4"), width=2)
        d.line((3, 7, 13, 3), fill=hexc("#b8b8c4"), width=2)
        d.ellipse((1, 11, 5, 15), outline=hexc("#c8463a"), width=2)
        d.ellipse((1, 5, 5, 9), outline=hexc("#c8463a"), width=2)
    return acabar(im)


# ------------------------------------------------------------------ culturas (16x32, fases 0..4)

VERDE = hexc("#5a9a3a")
VERDE_ESC = hexc("#3e7a2a")


def planta_base(d, fase, alto, verde=VERDE):
    """Desenha caule e folhas; devolve o topo (y)."""
    if fase == 0:
        d.point([(5, 30), (10, 29), (8, 31)], fill=hexc("#8a6a4a"))
        d.line((7, 30, 7, 28), fill=verde)
        d.point([(6, 28), (8, 27)], fill=verde)
        return 27
    altura = {1: 6, 2: 10, 3: 14}.get(fase, 16) * (1.8 if alto else 1.0)
    topo = int(31 - altura)
    d.line((7, 31, 7, topo), fill=VERDE_ESC)
    d.line((8, 31, 8, topo + 1), fill=VERDE_ESC)
    n = fase + 1
    for i in range(n):
        y = int(31 - altura * (0.25 + 0.7 * i / max(n, 1)))
        lado = -1 if i % 2 == 0 else 1
        x0 = 7 if lado < 0 else 8
        d.polygon([(x0, y), (x0 + lado * 6, y - 3), (x0 + lado * 4, y + 1)], fill=verde)
    if alto and fase >= 2:
        d.line((7, topo, 7, topo - 2), fill=verde)
    return topo


def cultura(id_, produto_cor, forma, alto):
    """Gera as 5 fases e a planta murcha."""
    for fase in range(5):
        im, d = tela(16, 32)
        topo = planta_base(d, min(fase, 3) if fase < 4 else 4, alto)
        if fase == 4:
            c = produto_cor
            if forma == "bola":
                if id_ == "abobora":
                    d.ellipse((1, 21, 14, 31), fill=c)
                    d.line((7, 22, 7, 30), fill=escuro(c, 0.25))
                    d.line((4, 23, 4, 29), fill=escuro(c, 0.2))
                    d.line((10, 23, 10, 29), fill=escuro(c, 0.2))
                else:
                    for (x, y) in [(3, topo + 6), (10, topo + 3), (5, topo + 12), (11, topo + 10)]:
                        d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=c)
                        d.point([(x - 1, y - 1)], fill=sem_sombra(claro(c, 0.5)))
            elif forma == "melancia":
                d.ellipse((1, 22, 14, 31), fill=c)
                for x in (4, 8, 11):
                    d.line((x, 23, x - 1, 30), fill=escuro(c, 0.4))
            elif forma == "flor":
                if id_ == "girassol":
                    d.ellipse((2, topo - 6, 13, topo + 5), fill=c)
                    d.ellipse((5, topo - 3, 10, topo + 2), fill=sem_sombra(hexc("#5a3a1a")))
                else:
                    for (x, y) in [(7, topo - 3), (4, topo - 1), (11, topo - 1), (5, topo + 2), (10, topo + 2)]:
                        d.ellipse((x - 2, y - 2, x + 1, y + 1), fill=c)
                    d.point([(7, topo)], fill=sem_sombra(hexc("#e8a82a")))
            elif forma == "baga":
                for (x, y) in [(3, topo + 4), (11, topo + 2), (5, topo + 9), (10, topo + 8), (7, topo + 13)]:
                    d.ellipse((x - 1, y - 1, x + 1, y + 1), fill=c)
            elif forma == "espiga":
                d.ellipse((9, topo + 4, 13, topo + 13), fill=c)
                d.ellipse((2, topo + 8, 6, topo + 16), fill=c)
                d.line((10, topo + 2, 9, topo - 2), fill=hexc("#c8a85a"))
            elif forma == "raiz":
                d.ellipse((4, 27, 11, 31), fill=c)
            elif forma == "folha":
                d.ellipse((1, 21, 14, 31), fill=c)
                d.ellipse((3, 22, 11, 29), fill=claro(c, 0.2))
                d.line((7, 30, 7, 24), fill=claro(c, 0.45))
        salvar(acabar(im), "culturas", "%s_%d" % (id_, fase))
    im, d = tela(16, 32)
    d.line((7, 31, 5, 22), fill=hexc("#7a6a4a"))
    d.line((8, 31, 11, 24), fill=hexc("#7a6a4a"))
    d.line((6, 26, 3, 25), fill=hexc("#8a7a5a"))
    salvar(acabar(im), "culturas", "morta")


# ------------------------------------------------------------------ objetos colocáveis

def obj(nome, w, h, desenho, **kw):
    im, d = tela(w, h)
    desenho(d, w, h)
    salvar(acabar(im, **kw), "objetos", nome)


def objetos():
    madeira = hexc("#9a6b3e")
    madeira_esc = hexc("#6e4826")
    metal = hexc("#9898a4")

    def bau(d, w, h):
        d.rectangle((1, h - 13, 14, h - 2), fill=madeira)
        d.rectangle((1, h - 15, 14, h - 10), fill=madeira_esc)
        d.line((1, h - 10, 14, h - 10), fill=hexc("#3a2414"))
        d.rectangle((6, h - 11, 9, h - 8), fill=sem_sombra(hexc("#e8c33a")))
    obj("bau", 16, 16, bau)

    def caixa(d, w, h):
        d.rectangle((1, h - 14, w - 2, h - 2), fill=hexc("#8a5a32"))
        d.rectangle((0, h - 18, w - 1, h - 13), fill=madeira_esc)
        for x in range(4, w - 2, 6):
            d.line((x, h - 12, x, h - 3), fill=hexc("#6e4826"))
        d.rectangle((w // 2 - 3, h - 17, w // 2 + 2, h - 15), fill=sem_sombra(hexc("#d8c08a")))
    obj("caixa_envio", 32, 24, caixa)

    def espantalho(d, w, h):
        d.line((7, h - 1, 7, 10), fill=madeira_esc, width=2)
        d.line((1, 15, 14, 15), fill=madeira_esc, width=2)
        d.rectangle((4, 13, 11, 22), fill=hexc("#4a6a9a"))
        d.line((4, 17, 11, 17), fill=hexc("#c8463a"))
        d.ellipse((4, 5, 11, 12), fill=hexc("#e8d8a0"))
        d.point([(6, 8), (9, 8)], fill=sem_sombra(hexc("#2a1a1a")))
        d.polygon([(2, 6), (13, 6), (7, 0)], fill=hexc("#a8843a"))
    obj("espantalho", 16, 32, espantalho)

    def aspersor(cor):
        def f(d, w, h):
            d.rectangle((6, 9, 9, 15), fill=cor)
            d.ellipse((3, 6, 12, 11), fill=escuro(cor, 0.1))
            d.ellipse((6, 7, 9, 9), fill=sem_sombra(hexc("#6ac8f0")))
        return f
    obj("aspersor", 16, 16, aspersor(metal))
    obj("aspersor_bom", 16, 16, aspersor(hexc("#e8c33a")))

    def cerca(d, w, h):
        d.rectangle((6, 2, 9, h - 1), fill=madeira)
        d.rectangle((0, 7, 15, 9), fill=madeira_esc)
        d.rectangle((0, 14, 15, 16), fill=madeira_esc)
    obj("cerca", 16, 24, cerca)

    def tocha(d, w, h):
        d.line((7, h - 1, 7, 12), fill=hexc("#4a3a2a"), width=2)
        d.rectangle((4, 4, 11, 12), fill=hexc("#3a3a3a"))
        d.rectangle((5, 5, 10, 11), fill=sem_sombra(hexc("#ffd27a")))
        d.rectangle((3, 2, 12, 4), fill=hexc("#2a2a2a"))
    obj("tocha", 16, 32, tocha)

    def barril(d, w, h):
        d.ellipse((2, 4, 13, h - 1), fill=hexc("#7a4a2a"))
        d.rectangle((2, 8, 13, h - 5), fill=hexc("#7a4a2a"))
        for y in (8, h - 6):
            d.line((2, y, 13, y), fill=hexc("#3a3a40"))
        d.ellipse((3, 3, 12, 7), fill=hexc("#5a3418"))
    obj("barril", 16, 24, barril)

    def conserveiro(d, w, h):
        d.rectangle((3, 8, 12, h - 1), fill=hexc("#d8c8a0"))
        d.rectangle((2, 5, 13, 8), fill=madeira_esc)
        d.rectangle((5, 12, 10, 18), fill=sem_sombra(hexc("#c86a4a")))
    obj("conserveiro", 16, 24, conserveiro)

    def fornalha(acesa):
        def f(d, w, h):
            d.polygon([(1, h - 1), (3, 8), (12, 8), (14, h - 1)], fill=hexc("#8a5a4a"))
            d.rectangle((5, 2, 10, 8), fill=hexc("#7a4a3a"))
            d.rectangle((5, h - 12, 10, h - 5), fill=sem_sombra(hexc("#ff8a3a") if acesa else hexc("#2a1a1a")))
            if acesa:
                d.point([(7, h - 9), (8, h - 10)], fill=sem_sombra(hexc("#ffe07a")))
        return f
    obj("fornalha", 16, 32, fornalha(False))
    obj("fornalha_on", 16, 32, fornalha(True))

    def forno(acesa):
        def f(d, w, h):
            d.rectangle((1, 6, 14, h - 1), fill=hexc("#5a5a5a"))
            d.pieslice((1, 0, 14, 12), 180, 360, fill=hexc("#6a6a6a"))
            d.rectangle((5, h - 9, 10, h - 3), fill=sem_sombra(hexc("#ff6a2a") if acesa else hexc("#1a1a1a")))
        return f
    obj("forno_carvao", 16, 24, forno(False))
    obj("forno_carvao_on", 16, 24, forno(True))

    def prensa(d, w, h):
        d.rectangle((1, h - 7, 14, h - 1), fill=hexc("#c8b88a"))
        d.rectangle((6, 6, 9, h - 7), fill=madeira_esc)
        d.rectangle((2, 4, 13, 7), fill=madeira)
        d.ellipse((4, h - 11, 11, h - 6), fill=sem_sombra(hexc("#f0c84a")))
    obj("prensa_queijo", 16, 24, prensa)

    def batedeira(d, w, h):
        d.rectangle((2, 8, 13, h - 1), fill=hexc("#e8e0c8"))
        d.ellipse((4, 10, 11, 17), fill=hexc("#c8b880"))
        d.rectangle((6, 2, 9, 8), fill=metal)
    obj("batedeira", 16, 24, batedeira)

    def tear(d, w, h):
        d.rectangle((1, 6, 2, h - 1), fill=madeira)
        d.rectangle((13, 6, 14, h - 1), fill=madeira)
        d.rectangle((1, 5, 14, 7), fill=madeira_esc)
        d.rectangle((1, h - 8, 14, h - 6), fill=madeira_esc)
        for x in range(4, 13, 2):
            d.line((x, 8, x, h - 9), fill=sem_sombra(hexc("#e8d8f0")))
        d.rectangle((4, 14, 11, 19), fill=sem_sombra(hexc("#c8b8e8")))
    obj("tear", 16, 32, tear)

    def colmeia(d, w, h):
        d.rectangle((2, 6, 13, h - 1), fill=hexc("#e8b04a"))
        d.rectangle((1, 3, 14, 6), fill=hexc("#8a5a2a"))
        d.line((2, 12, 13, 12), fill=hexc("#c8902a"))
        d.rectangle((6, h - 5, 9, h - 4), fill=sem_sombra(hexc("#2a1a0a")))
    obj("caixa_abelha", 16, 24, colmeia)

    def fogao(d, w, h):
        d.rectangle((2, 10, w - 3, h - 1), fill=hexc("#5a5a64"))
        d.rectangle((2, 8, w - 3, 11), fill=hexc("#7a7a84"))
        d.ellipse((6, 7, 12, 11), fill=hexc("#2a2a2a"))
        d.ellipse((18, 7, 24, 11), fill=hexc("#2a2a2a"))
        d.rectangle((7, 15, w - 8, h - 5), fill=hexc("#3a3a44"))
        d.rectangle((24, 0, 28, 8), fill=hexc("#4a4a54"))
    obj("fogao", 32, 32, fogao)

    def cama(d, w, h):
        d.rectangle((1, 2, w - 2, h - 1), fill=madeira)
        d.rectangle((3, 4, w - 4, h - 4), fill=hexc("#ecebf4"))
        d.rectangle((3, 18, w - 4, h - 4), fill=hexc("#5a7ac8"))
        d.line((3, 26, w - 4, 26), fill=hexc("#4a6ab8"))
        d.rectangle((7, 6, w - 8, 12), fill=sem_sombra(hexc("#ffffff")))
    obj("cama", 32, 48, cama)

    def cocho(cheio):
        def f(d, w, h):
            d.rectangle((1, h - 9, w - 2, h - 1), fill=madeira_esc)
            d.rectangle((3, h - 9, w - 4, h - 6), fill=hexc("#3a2414"))
            if cheio:
                for x in range(3, w - 4, 2):
                    d.line((x, h - 6, x + 1, h - 11), fill=sem_sombra(hexc("#d8c26a")))
        return f
    obj("cocho", 32, 16, cocho(False))
    obj("cocho_cheio", 32, 16, cocho(True))

    def mural(d, w, h):
        d.rectangle((14, 20, 17, h - 1), fill=madeira_esc)
        d.rectangle((2, 2, w - 3, 21), fill=madeira)
        d.rectangle((4, 4, w - 5, 19), fill=hexc("#b08a5a"))
        d.rectangle((6, 6, 13, 15), fill=sem_sombra(hexc("#f8f0d8")))
        d.rectangle((17, 7, 25, 14), fill=sem_sombra(hexc("#f0e8c8")))
        d.point([(9, 6), (21, 7)], fill=sem_sombra(hexc("#c8463a")))
    obj("mural", 32, 32, mural)

    def escada_mina(d, w, h):
        d.rectangle((1, 1, 14, 14), fill=hexc("#1a1210"))
        d.line((4, 1, 4, 14), fill=madeira)
        d.line((11, 1, 11, 14), fill=madeira)
        for y in (3, 7, 11):
            d.line((4, y, 11, y), fill=madeira)
    obj("escada_mina", 16, 16, escada_mina, sombra=False)

    def elevador(d, w, h):
        d.rectangle((2, 2, w - 3, h - 1), fill=hexc("#5a5a64"))
        d.rectangle((5, 6, w - 6, h - 1), fill=hexc("#22222a"))
        d.line((w // 2, 6, w // 2, h - 1), fill=hexc("#3a3a44"))
        d.ellipse((w // 2 - 2, 2, w // 2 + 1, 5), fill=sem_sombra(hexc("#e8c33a")))
    obj("elevador", 32, 32, elevador)

    def mesa(d, w, h):
        d.rectangle((1, 4, w - 2, 9), fill=hexc("#8a5a32"))
        d.rectangle((3, 9, 5, h - 1), fill=madeira_esc)
        d.rectangle((w - 6, 9, w - 4, h - 1), fill=madeira_esc)
        d.ellipse((10, 1, 15, 5), fill=sem_sombra(hexc("#e8e0f0")))
        d.line((12, 0, 13, 2), fill=hexc("#e84a6a"))
    obj("mesa", 32, 24, mesa)

    def caminho(d, w, h):
        for (x, y, r) in [(3, 4, 3), (11, 3, 3), (7, 9, 3), (2, 12, 2), (12, 12, 3)]:
            d.ellipse((x - r, y - r, x + r, y + r), fill=hexc("#9a9a94"))
    obj("caminho", 16, 16, caminho)

    def mato(variante):
        def f(d, w, h):
            base = [(2, 4, 11), (5, 7, 13), (9, 6, 12), (12, 9, 14)]
            for i, (x, alt, y0) in enumerate(base):
                if (i + variante) % 4 == 3:
                    continue
                d.polygon([(x - 2, 15), (x + (variante % 2), 15 - alt), (x + 2, 15)], fill=hexc("#6a9a3a") if i % 2 else hexc("#7aaa44"))
        return f
    for v in range(3):
        obj("mato_%d" % v, 16, 16, mato(v))

    def muda(d, w, h):
        d.line((7, h - 1, 7, h - 10), fill=hexc("#6a4a2a"))
        d.ellipse((2, h - 15, 9, h - 8), fill=hexc("#5a9a3a"))
        d.ellipse((6, h - 16, 13, h - 9), fill=hexc("#6aaa44"))
    obj("muda", 16, 16, muda)


# ------------------------------------------------------------------ animais (olhando para a direita)

def animais():
    def galinha(cor, crista, quadro, pato=False):
        im, d = tela(16, 16)
        pe = 1 if quadro else 0
        d.line((6, 13, 6 - pe, 15), fill=hexc("#e8a82a"))
        d.line((9, 13, 9 + pe, 15), fill=hexc("#e8a82a"))
        d.ellipse((2, 6, 12, 14), fill=cor)
        d.polygon([(2, 8), (0, 5), (3, 7)], fill=escuro(cor, 0.1))
        d.ellipse((8, 2, 14, 8), fill=cor)
        bico = hexc("#f0a020")
        if pato:
            d.rectangle((13, 5, 15, 6), fill=bico)
        else:
            d.polygon([(14, 4), (15, 5), (14, 6)], fill=bico)
            d.rectangle((10, 1, 11, 2), fill=crista)
        d.point([(12, 4)], fill=sem_sombra(hexc("#1a1a1a")))
        d.line((5, 10, 8, 9), fill=escuro(cor, 0.15))
        return acabar(im)

    def quadrupede(cor, quadro, tipo):
        im, d = tela(32, 24)
        perna = escuro(cor, 0.35)
        dl = 1 if quadro else 0
        for x, desl in [(7, dl), (11, -dl), (19, dl), (23, -dl)]:
            d.rectangle((x + desl, 16, x + desl + 1, 22), fill=perna)
        if tipo == "ovelha":
            for (x, y) in [(8, 9), (13, 7), (18, 7), (22, 9), (10, 13), (16, 13), (21, 13)]:
                d.ellipse((x - 4, y - 4, x + 4, y + 4), fill=cor)
            d.ellipse((24, 4, 31, 12), fill=hexc("#3a3a3a"))
            d.point([(29, 7)], fill=sem_sombra(hexc("#ffffff")))
        else:
            d.ellipse((3, 6, 27, 18), fill=cor)
            if tipo == "vaca":
                d.ellipse((8, 8, 13, 12), fill=sem_sombra(hexc("#3a2a2a")))
                d.ellipse((17, 11, 21, 15), fill=sem_sombra(hexc("#3a2a2a")))
                d.ellipse((12, 15, 16, 18), fill=sem_sombra(hexc("#f0a8b0")))
            d.ellipse((23, 3, 31, 12), fill=escuro(cor, 0.05))
            d.rectangle((27, 8, 31, 11), fill=claro(cor, 0.2) if tipo == "cabra" else hexc("#e8b8b0"))
            d.point([(27, 6)], fill=sem_sombra(hexc("#1a1a1a")))
            if tipo == "vaca":
                d.line((24, 3, 22, 1), fill=hexc("#e8e0c8"))
            else:
                d.line((25, 3, 22, 0), fill=hexc("#8a7a6a"))
                d.line((29, 12, 29, 14), fill=hexc("#d8c8b0"))
            d.line((3, 9, 1, 13), fill=escuro(cor, 0.3))
        return acabar(im)

    for q in (0, 1):
        salvar(galinha(hexc("#f4ece0"), hexc("#d8283c"), q), "animais", "galinha_%d" % q)
        salvar(galinha(hexc("#f0f0e8"), hexc("#d8283c"), q, pato=True), "animais", "pato_%d" % q)
        salvar(quadrupede(hexc("#f2ece4"), q, "vaca"), "animais", "vaca_%d" % q)
        salvar(quadrupede(hexc("#d8c8b0"), q, "cabra"), "animais", "cabra_%d" % q)
        salvar(quadrupede(hexc("#f8f6ee"), q, "ovelha"), "animais", "ovelha_%d" % q)


# ------------------------------------------------------------------ monstros

def monstros():
    def gosma(cor, quadro):
        im, d = tela(16, 16)
        if quadro:
            d.ellipse((1, 7, 14, 15), fill=cor)
            d.ellipse((3, 5, 12, 13), fill=cor)
        else:
            d.ellipse((2, 4, 13, 15), fill=cor)
        d.rectangle((5, 8, 6, 10), fill=sem_sombra(hexc("#ffffff")))
        d.rectangle((9, 8, 10, 10), fill=sem_sombra(hexc("#ffffff")))
        d.point([(6, 9), (10, 9)], fill=sem_sombra(hexc("#101010")))
        d.point([(4, 6), (5, 6)], fill=sem_sombra(claro(cor, 0.6)))
        return acabar(im)

    def morcego(quadro):
        im, d = tela(16, 16)
        cor = hexc("#4a3a5a")
        if quadro:
            d.polygon([(7, 7), (0, 2), (2, 9), (5, 9)], fill=cor)
            d.polygon([(8, 7), (15, 2), (13, 9), (10, 9)], fill=cor)
        else:
            d.polygon([(7, 7), (0, 11), (3, 12), (5, 10)], fill=cor)
            d.polygon([(8, 7), (15, 11), (12, 12), (10, 10)], fill=cor)
        d.ellipse((5, 5, 10, 11), fill=hexc("#3a2a4a"))
        d.point([(6, 7), (9, 7)], fill=sem_sombra(hexc("#ff4a4a")))
        d.point([(5, 4), (10, 4)], fill=hexc("#3a2a4a"))
        return acabar(im)

    def pedrento(quadro):
        im, d = tela(16, 16)
        cor = hexc("#7a7068")
        y = 1 if quadro else 0
        d.polygon([(1, 15), (2, 6 + y), (6, 2 + y), (11, 3 + y), (14, 8 + y), (14, 15)], fill=cor)
        d.point([(5, 8 + y), (10, 8 + y)], fill=sem_sombra(hexc("#ffd24a")))
        d.line((4, 12, 11, 12), fill=escuro(cor, 0.35))
        return acabar(im)

    for q in (0, 1):
        salvar(gosma(hexc("#5fc24a"), q), "monstros", "gosma_%d" % q)
        salvar(gosma(hexc("#4a8ad8"), q), "monstros", "gosma_azul_%d" % q)
        salvar(gosma(hexc("#9a4ac8"), q), "monstros", "gosma_roxa_%d" % q)
        salvar(morcego(q), "monstros", "morcego_%d" % q)
        salvar(pedrento(q), "monstros", "pedrento_%d" % q)


# ------------------------------------------------------------------ catálogo de itens

ITENS = {
    "sem_alface": ("semente", "#9bc26b"), "sem_batata": ("semente", "#c19a6b"), "sem_morango": ("semente", "#e2526a"),
    "sem_couve": ("semente", "#4f9e4a"), "sem_margarida": ("semente", "#f2f2f2"), "sem_tomate": ("semente", "#d9412b"),
    "sem_milho": ("semente", "#e8c33a"), "sem_melancia": ("semente", "#3c8a3e"), "sem_pimenta": ("semente", "#c8261b"),
    "sem_girassol": ("semente", "#f0b81d"), "sem_abobora": ("semente", "#e07b23"), "sem_berinjela": ("semente", "#6b3a8a"),
    "sem_inhame": ("semente", "#9a6b4b"), "sem_uva": ("semente", "#7a3f9e"), "sem_mista": ("semente", "#a0a070"),
    "alface": ("folha", "#9bc26b"), "batata": ("batata", "#c19a6b"), "morango": ("morango", "#e2526a"),
    "couve": ("folha", "#4f9e4a"), "margarida": ("flor_branca", "#f7f7f0"), "tomate": ("bola", "#d9412b"),
    "milho": ("milho", "#e8c33a"), "melancia": ("melancia", "#3c8a3e"), "pimenta": ("pimenta", "#c8261b"),
    "girassol": ("girassol", "#f0b81d"), "abobora": ("abobora", "#e07b23"), "berinjela": ("berinjela", "#6b3a8a"),
    "inhame": ("raiz", "#9a6b4b"), "uva": ("uva", "#7a3f9e"),
    "madeira": ("tronco", "#9a6b3e"), "pedra": ("pedra", "#9a9a94"), "fibra": ("fibra", "#7fa04a"),
    "seiva": ("garrafa", "#c98a2a"), "argila": ("pedra", "#b0714a"), "carvao": ("pedra", "#3a3a3a"),
    "feno": ("fibra", "#d8c26a"), "madeira_dura": ("tronco", "#6a4426"),
    "minerio_cobre": ("minerio", "#d8844a"), "minerio_ferro": ("minerio", "#d8d8e4"), "minerio_ouro": ("minerio", "#f0cc3a"),
    "barra_cobre": ("barra", "#c87443"), "barra_ferro": ("barra", "#b8b8c4"), "barra_ouro": ("barra", "#e8c33a"),
    "quartzo": ("gema", "#e8eef2"), "ametista": ("gema", "#9b59c8"), "esmeralda": ("gema", "#2eb872"),
    "rubi": ("gema", "#d8283c"), "diamante": ("gema", "#bfefff"), "gosma": ("gosma", "#5fc24a"),
    "asa_morcego": ("asa", "#4a3a5a"),
    "alho_selvagem": ("alho", "#e8e4cf"), "dente_leao": ("flor_amarela", "#f0d02a"), "amora": ("amora", "#5a2a6e"),
    "flor_silvestre": ("flor", "#e87ab0"), "cogumelo": ("cogumelo", "#c8875a"), "avela": ("bola_marrom", "#8a5a2a"),
    "raiz_inverno": ("raiz", "#d8c8a8"), "cristal_gelo": ("gema", "#cfe8ff"),
    "lambari": ("peixe", "#c8d0d8"), "tilapia": ("peixe", "#8a9aa8"), "traira": ("peixe", "#5a6a3a"),
    "carpa": ("peixe", "#b89a4a"), "bagre": ("bagre", "#6a5a4a"), "dourado": ("peixe", "#e8a82a"),
    "enguia": ("enguia", "#3a4a3a"), "pintado": ("pintado", "#9aa0a0"), "peixe_gelo": ("peixe", "#a8d8f0"),
    "peixe_orvalho": ("brilho", "#7ad8e8"), "bota_velha": ("bota", "#5a4030"), "alga": ("folha", "#3a7a4a"),
    "ovo": ("ovo", "#f2ead8"), "ovo_grande": ("ovo", "#f8efe0"), "leite": ("garrafa", "#f8f8f8"),
    "leite_grande": ("garrafa", "#ffffff"), "leite_cabra": ("garrafa", "#f2f0e2"), "la": ("la", "#f0ece0"),
    "geleia": ("pote", "#c8263a"), "conserva": ("pote", "#7a9a3a"), "suco": ("garrafa", "#7ab83a"),
    "licor": ("garrafa", "#8a1a4a"), "queijo": ("queijo", "#f0c84a"), "queijo_cabra": ("queijo", "#f2e2a8"),
    "maionese": ("pote", "#f8f0c0"), "tecido": ("tecido", "#c8b8e8"), "mel": ("pote", "#f0b030"),
    "omelete": ("prato_monte", "#f2d24a"), "salada": ("prato_monte", "#7ab84a"), "sopa_abobora": ("prato_sopa", "#e07b23"),
    "peixe_assado": ("prato_peixe", "#c88a4a"), "torta_morango": ("prato_torta", "#e2526a"),
    "batata_frita": ("prato_monte", "#d8b04a"), "milho_assado": ("milho", "#d8a82a"), "cafe": ("xicara", "#4a2a1a"),
    "pao_queijo": ("prato_monte", "#f0d08a"), "pocao": ("garrafa", "#d84a5a"),
    "fertilizante": ("saco", "#6a4a2a"), "adubo_rapido": ("saco", "#4a8a3a"), "isca": ("isca", "#b86a5a"),
    "escada": ("escada", "#9a6b3e"), "buque": ("buque", "#f08ab0"), "anel_orvalho": ("anel", "#7ad8e8"),
    "chave_estufa": ("chave", "#e8c33a"),
    "pessego": ("bola", "#f0a070"), "laranja": ("bola", "#f08a1a"), "maca": ("bola", "#d83a3a"), "roma": ("bola", "#b8283a"),
    "muda_pessegueiro": ("muda", "#f0a070"), "muda_laranjeira": ("muda", "#f08a1a"), "muda_macieira": ("muda", "#d83a3a"),
    "muda_romazeira": ("muda", "#b8283a"), "semente_arvore": ("bolota", "#a8783a"),
}


def item(id_, forma, cor_hex):
    c = hexc(cor_hex)
    f = {
        "semente": it_semente, "folha": it_folha, "bola": it_bola, "batata": it_batata, "morango": it_morango,
        "milho": it_milho, "melancia": it_melancia, "pimenta": it_pimenta, "girassol": it_girassol,
        "berinjela": it_berinjela, "raiz": it_raiz, "uva": it_uva, "tronco": it_tronco, "pedra": it_pedra,
        "fibra": it_fibra, "garrafa": it_garrafa, "minerio": it_minerio, "barra": it_barra, "gema": it_gema,
        "alho": it_alho, "amora": it_amora, "flor": it_flor, "cogumelo": it_cogumelo, "ovo": it_ovo,
        "la": it_la, "pote": it_pote, "queijo": it_queijo, "tecido": it_tecido, "xicara": it_xicara,
        "saco": it_saco, "isca": it_isca, "escada": it_escada, "buque": it_buque, "anel": it_anel,
        "chave": it_chave, "bota": it_bota, "muda": it_muda, "bolota": it_bolota,
    }
    if forma in f:
        return f[forma](c)
    if forma == "abobora":
        return it_bola(c, gomos=True)
    if forma == "bola_marrom":
        return it_bola(c)
    if forma == "flor_branca":
        return it_flor(c)
    if forma == "flor_amarela":
        return it_flor(c, "#c88a1a")
    if forma in ("peixe", "bagre", "enguia", "pintado", "brilho"):
        return it_peixe(c, {"peixe": "normal"}.get(forma, forma))
    if forma.startswith("prato_"):
        return it_prato(c, forma[6:])
    if forma == "gosma":
        im, d = tela()
        d.ellipse((2, 5, 13, 14), fill=c)
        d.point([(5, 7), (6, 7)], fill=sem_sombra(claro(c, 0.6)))
        return acabar(im)
    if forma == "asa":
        im, d = tela()
        d.polygon([(1, 4), (8, 8), (15, 4), (12, 12), (8, 10), (4, 12)], fill=c)
        return acabar(im)
    raise ValueError(forma)


CULTURAS = {
    "alface": ("folha", False), "batata": ("raiz", False), "morango": ("baga", False), "couve": ("folha", False),
    "margarida": ("flor", False), "tomate": ("bola", True), "milho": ("espiga", True), "melancia": ("melancia", False),
    "pimenta": ("baga", False), "girassol": ("flor", True), "abobora": ("bola", False), "berinjela": ("raiz", False),
    "inhame": ("raiz", False), "uva": ("baga", True),
}


def main():
    for id_, (forma, cor) in ITENS.items():
        salvar(item(id_, forma, cor), "itens", id_)
    for f in ["enxada", "regador", "machado", "picareta", "foice"]:
        for n in range(4):
            salvar(ferramenta(f, n), "itens", "%s_%d" % (f, n))
    for f in ["vara", "vara_fibra", "espada", "espada_aco", "balde", "tesoura"]:
        salvar(ferramenta(f, 0), "itens", f)
    for id_, (forma, alto) in CULTURAS.items():
        cultura(id_, hexc(ITENS[id_][1]), forma, alto)
    objetos()
    animais()
    monstros()
    # folha de conferência
    pastas = ["itens", "culturas", "objetos", "animais", "monstros"]
    imagens = []
    for p in pastas:
        for n in sorted(x for x in os.listdir(os.path.join(RAIZ, p)) if x.endswith(".png")):
            imagens.append(Image.open(os.path.join(RAIZ, p, n)))
    col = 20
    cel = 52
    linhas = (len(imagens) + col - 1) // col
    folha = Image.new("RGBA", (col * cel, linhas * cel), (70, 90, 70, 255))
    for i, im in enumerate(imagens):
        esc = min(48 // im.width, 48 // im.height) or 1
        im2 = im.resize((im.width * esc, im.height * esc), Image.NEAREST)
        folha.paste(im2, ((i % col) * cel + (cel - im2.width) // 2, (i // col) * cel + (cel - im2.height) // 2), im2)
    os.makedirs(os.path.join(RAIZ, "..", "..", "ferramentas", "prints"), exist_ok=True)
    folha.save(os.path.join(RAIZ, "..", "..", "ferramentas", "prints", "folha_artes.png"))
    print("ok:", len(imagens), "imagens")


if __name__ == "__main__":
    main()
