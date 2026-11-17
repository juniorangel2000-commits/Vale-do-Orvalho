#!/usr/bin/env python3
"""Sintetiza os efeitos sonoros e as músicas do Vale do Orvalho (nada é baixado de fora).

Efeitos: som/efeitos/*.wav     Músicas: som/musica/*.ogg (precisa do ffmpeg)
Rodar da raiz do projeto:  python3 ferramentas/gerar_sons.py
"""
import os
import subprocess
import wave

import numpy as np

TAXA = 22050
AQUI = os.path.dirname(os.path.abspath(__file__))
SOM = os.path.join(AQUI, "..", "som")
rng = np.random.default_rng(7)


# ------------------------------------------------------------------ básicos

def t(dur):
    return np.arange(int(TAXA * dur)) / TAXA


def env(n, ataque=0.005, queda=0.2, total=None):
    """Envelope ataque rápido + queda exponencial."""
    x = np.arange(n) / TAXA
    a = np.clip(x / max(ataque, 1e-4), 0, 1)
    return a * np.exp(-x / max(queda, 1e-4))


def seno(f, dur, fase=0.0):
    return np.sin(2 * np.pi * f * t(dur) + fase)


def tri(f, dur):
    x = t(dur) * f
    return 2 * np.abs(2 * (x - np.floor(x + 0.5))) - 1


def quad(f, dur, larg=0.5):
    x = (t(dur) * f) % 1.0
    return np.where(x < larg, 1.0, -1.0)


def ruido(dur):
    return rng.uniform(-1, 1, int(TAXA * dur))


def passa_baixa(x, corte):
    """Filtro de um polo (simples, suficiente aqui)."""
    a = np.exp(-2 * np.pi * corte / TAXA)
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def passa_alta(x, corte):
    return x - passa_baixa(x, corte)


def varredura(f0, f1, dur, forma=np.sin):
    n = int(TAXA * dur)
    f = np.linspace(f0, f1, n)
    fase = 2 * np.pi * np.cumsum(f) / TAXA
    return forma(fase)


def juntar(*partes):
    n = max(len(p) for p in partes)
    s = np.zeros(n)
    for p in partes:
        s[: len(p)] += p
    return s


def concat(*partes):
    return np.concatenate(partes)


def silencio(dur):
    return np.zeros(int(TAXA * dur))


def normalizar(x, pico=0.8):
    m = np.max(np.abs(x)) or 1.0
    return x / m * pico


def salvar_wav(x, caminho):
    os.makedirs(os.path.dirname(caminho), exist_ok=True)
    dados = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(caminho, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(TAXA)
        w.writeframes(dados.tobytes())


# ------------------------------------------------------------------ efeitos

def efeitos():
    e = {}
    n = ruido(0.12)
    e["enxada"] = juntar(passa_baixa(n, 900) * env(len(n), 0.002, 0.05) * 1.6, seno(85, 0.15) * env(int(TAXA * 0.15), 0.002, 0.05))
    n = ruido(0.45)
    e["regar"] = passa_alta(passa_baixa(n, 3500), 600) * env(len(n), 0.06, 0.25) * 0.9
    n = ruido(0.1)
    e["machado"] = juntar(passa_baixa(n, 2500) * env(len(n), 0.001, 0.03) * 1.3, seno(190, 0.12) * env(int(TAXA * 0.12), 0.001, 0.04))
    e["picareta"] = juntar(seno(1250, 0.3) * env(int(TAXA * 0.3), 0.001, 0.06), seno(1870, 0.3) * env(int(TAXA * 0.3), 0.001, 0.05) * 0.6,
                           passa_baixa(ruido(0.05), 4000) * env(int(TAXA * 0.05), 0.001, 0.01))
    e["quebrar"] = juntar(passa_baixa(ruido(0.3), 1500) * env(int(TAXA * 0.3), 0.001, 0.09) * 1.4, seno(120, 0.2) * env(int(TAXA * 0.2), 0.001, 0.06))
    e["arvore_cai"] = juntar(passa_baixa(ruido(0.9), 400) * env(int(TAXA * 0.9), 0.15, 0.3) * 1.5, varredura(160, 50, 0.9) * env(int(TAXA * 0.9), 0.1, 0.35) * 0.6)
    e["foice"] = passa_alta(ruido(0.15), 2500) * env(int(TAXA * 0.15), 0.02, 0.05)
    e["colher"] = varredura(380, 900, 0.09) * env(int(TAXA * 0.09), 0.002, 0.05)
    e["pegar"] = concat(seno(880, 0.05) * env(int(TAXA * 0.05), 0.002, 0.03), seno(1175, 0.08) * env(int(TAXA * 0.08), 0.002, 0.05))
    e["moeda"] = concat(tri(988, 0.07) * env(int(TAXA * 0.07), 0.002, 0.06), tri(1319, 0.25) * env(int(TAXA * 0.25), 0.002, 0.12))
    e["clique"] = seno(1500, 0.03) * env(int(TAXA * 0.03), 0.001, 0.008)
    e["abrir"] = concat(seno(660, 0.04) * env(int(TAXA * 0.04), 0.002, 0.02), seno(990, 0.06) * env(int(TAXA * 0.06), 0.002, 0.03))
    e["fechar"] = concat(seno(990, 0.04) * env(int(TAXA * 0.04), 0.002, 0.02), seno(660, 0.06) * env(int(TAXA * 0.06), 0.002, 0.03))
    e["porta"] = juntar(seno(110, 0.2) * env(int(TAXA * 0.2), 0.002, 0.05), passa_baixa(ruido(0.12), 700) * env(int(TAXA * 0.12), 0.002, 0.04))
    e["plantar"] = passa_baixa(ruido(0.1), 1200) * env(int(TAXA * 0.1), 0.01, 0.04)
    e["lancar"] = juntar(varredura(1600, 500, 0.25) * env(int(TAXA * 0.25), 0.01, 0.12) * 0.3, passa_alta(ruido(0.25), 3000) * env(int(TAXA * 0.25), 0.05, 0.08) * 0.5)
    e["splash"] = passa_baixa(ruido(0.4), 2200) * env(int(TAXA * 0.4), 0.003, 0.12)
    e["fisgou"] = concat(seno(1320, 0.06) * env(int(TAXA * 0.06), 0.002, 0.04), seno(1760, 0.12) * env(int(TAXA * 0.12), 0.002, 0.06))
    e["peixe"] = concat(*[tri(f, 0.08) * env(int(TAXA * 0.08), 0.002, 0.06) for f in (784, 988, 1175, 1568)])
    e["dano"] = quad(110, 0.18, 0.3) * env(int(TAXA * 0.18), 0.002, 0.08) * 0.5
    e["golpe"] = juntar(passa_alta(ruido(0.1), 1500) * env(int(TAXA * 0.1), 0.002, 0.03), varredura(500, 200, 0.1) * env(int(TAXA * 0.1), 0.002, 0.04))
    e["monstro"] = varredura(300, 120, 0.2) * env(int(TAXA * 0.2), 0.005, 0.08) * (0.6 + 0.4 * seno(30, 0.2))
    e["morreu"] = juntar(varredura(500, 80, 0.4) * env(int(TAXA * 0.4), 0.005, 0.15), passa_baixa(ruido(0.3), 900) * env(int(TAXA * 0.3), 0.002, 0.1) * 0.6)
    e["nivel"] = concat(*[tri(f, 0.1) * env(int(TAXA * 0.1), 0.002, 0.09) for f in (523, 659, 784)], tri(1047, 0.5) * env(int(TAXA * 0.5), 0.002, 0.25))
    e["comer"] = concat(*[passa_baixa(ruido(0.07), 1800) * env(int(TAXA * 0.07), 0.002, 0.03) for _ in range(3)])
    e["dormir"] = concat(*[seno(f, 0.35) * env(int(TAXA * 0.35), 0.01, 0.25) for f in (784, 659, 523, 392)])
    e["erro"] = quad(150, 0.15, 0.5) * env(int(TAXA * 0.15), 0.002, 0.06) * 0.35
    e["galinha"] = concat(varredura(900, 1300, 0.06) * env(int(TAXA * 0.06), 0.002, 0.03), silencio(0.03), varredura(1000, 1500, 0.08) * env(int(TAXA * 0.08), 0.002, 0.04))
    e["vaca"] = varredura(160, 120, 0.7) * (0.5 + 0.5 * quad(160, 0.7, 0.4)) * env(int(TAXA * 0.7), 0.08, 0.4) * 0.5
    e["escada"] = concat(*[passa_baixa(ruido(0.06), 1500) * env(int(TAXA * 0.06), 0.002, 0.02) for _ in range(4)])
    for nome, x in e.items():
        salvar_wav(normalizar(x, 0.7), os.path.join(SOM, "efeitos", nome + ".wav"))
    # chuva ambiente (laço de 8 s, as pontas se misturam para emendar sem estalo)
    n = passa_baixa(passa_alta(ruido(8.5), 500), 4000)
    gotas = np.zeros_like(n)
    for _ in range(140):
        i = rng.integers(0, len(n) - 800)
        gotas[i:i + 800] += seno(rng.uniform(1800, 3200), 800 / TAXA) * env(800, 0.001, 0.008) * 0.4
    n = n * 0.6 + gotas
    cauda = int(TAXA * 0.5)
    laco = n[:-cauda].copy()
    mistura = np.linspace(0, 1, cauda)
    laco[:cauda] = laco[:cauda] * mistura + n[-cauda:] * (1 - mistura)
    salvar_wav(normalizar(laco, 0.5), os.path.join(SOM, "efeitos", "chuva.wav"))
    return len(e)


# ------------------------------------------------------------------ música

NOTAS = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


def freq(midi):
    return 440.0 * 2 ** ((midi - 69) / 12.0)


def acorde(nome, oitava=4):
    """'Am' -> [57, 60, 64]; 'C' -> [60, 64, 67]."""
    menor = nome.endswith("m")
    raiz = NOTAS[nome.rstrip("m")]
    base = 12 * (oitava + 1) + raiz
    return [base, base + (3 if menor else 4), base + 7]


def instrumento(tipo, f, dur, vol=1.0):
    n = int(TAXA * dur)
    if n <= 0:
        return np.zeros(0)
    if tipo == "pluck":
        x = tri(f, dur) * 0.6 + seno(f * 2, dur) * 0.2
        return x * env(n, 0.004, min(0.35, dur)) * vol
    if tipo == "marimba":
        x = seno(f, dur) + 0.3 * seno(f * 4, dur) * np.exp(-t(dur) * 30)
        return x * env(n, 0.002, 0.25) * vol
    if tipo == "flauta":
        vib = 1 + 0.004 * np.sin(2 * np.pi * 5 * t(dur))
        fase = 2 * np.pi * np.cumsum(np.full(n, f) * vib) / TAXA
        x = np.sin(fase) + 0.15 * np.sin(2 * fase)
        a = np.minimum(1, np.arange(n) / (TAXA * 0.04))
        r = np.minimum(1, (n - np.arange(n)) / (TAXA * 0.08))
        return x * a * r * vol
    if tipo == "sino":
        x = seno(f, dur) + 0.5 * seno(f * 2.76, dur) * np.exp(-t(dur) * 6) + 0.25 * seno(f * 5.4, dur) * np.exp(-t(dur) * 10)
        return x * env(n, 0.002, 0.9) * vol
    if tipo == "baixo":
        x = seno(f, dur) + 0.25 * tri(f, dur)
        return x * env(n, 0.01, dur * 0.8) * vol
    if tipo == "pad":
        x = (seno(f, dur) + seno(f * 1.003, dur) + 0.5 * seno(f * 2.001, dur)) / 2.5
        a = np.minimum(1, np.arange(n) / (TAXA * 0.5))
        r = np.minimum(1, (n - np.arange(n)) / (TAXA * 0.5))
        return x * a * r * vol
    raise ValueError(tipo)


def por(buf, inicio, som):
    i = int(inicio * TAXA)
    fim = min(len(buf), i + len(som))
    if fim > i:
        buf[i:fim] += som[: fim - i]


def escala(tom, menor):
    raiz = NOTAS[tom]
    passos = [0, 2, 3, 5, 7, 8, 10] if menor else [0, 2, 4, 5, 7, 9, 11]
    return [raiz + p for p in passos]


def musica(nome, progressao, bpm, tom, menor, acomp, melodia_inst, semente, densidade=0.6, oitava_mel=5, sem_melodia_a_cada=0):
    r = np.random.default_rng(semente)
    batida = 60.0 / bpm
    compasso = batida * 4
    total = compasso * len(progressao) * 2
    buf = np.zeros(int(TAXA * (total + 2)))
    esc = escala(tom, menor)
    # motivo de melodia: ritmo e graus, repetido com variação
    ritmos = []
    for _ in range(4):
        rit = []
        pos = 0.0
        while pos < 4:
            d = r.choice([0.5, 0.5, 1.0, 1.0, 1.5, 2.0])
            d = min(d, 4 - pos)
            rit.append((pos, d, r.random() < densidade))
            pos += d
        ritmos.append(rit)
    for volta in range(2):
        for i, ac in enumerate(progressao):
            ini = (volta * len(progressao) + i) * compasso
            notas = acorde(ac, 3)
            # baixo
            por(buf, ini, instrumento("baixo", freq(notas[0] - 12), batida * 1.8, 0.35))
            por(buf, ini + batida * 2, instrumento("baixo", freq(notas[0] - 12 + 7), batida * 1.8, 0.28))
            # acompanhamento
            if acomp == "pad":
                for nn in notas:
                    por(buf, ini, instrumento("pad", freq(nn + 12), compasso, 0.12))
            else:
                padrao = [0, 1, 2, 1, 0, 1, 2, 1]
                for k, p in enumerate(padrao):
                    por(buf, ini + k * batida / 2, instrumento(acomp, freq(notas[p] + 12), batida, 0.16))
            # melodia
            if sem_melodia_a_cada and i % sem_melodia_a_cada == sem_melodia_a_cada - 1:
                continue
            rit = ritmos[(i + volta) % 4 if i % 4 != 3 else 3]
            for (pos, d, toca) in rit:
                if not toca:
                    continue
                if r.random() < 0.6:
                    nota = r.choice(notas) + 12 * (oitava_mel - 3)
                else:
                    grau = r.integers(0, 7)
                    nota = esc[grau] + 12 * (oitava_mel + 1)
                por(buf, ini + pos * batida, instrumento(melodia_inst, freq(nota), d * batida * 0.95, 0.22))
    # eco leve
    atraso = int(TAXA * batida * 0.75)
    eco = np.zeros_like(buf)
    eco[atraso:] = buf[:-atraso] * 0.25
    buf = buf + eco
    buf = buf[: int(TAXA * total)]
    buf = normalizar(buf, 0.6)
    tmp = os.path.join(SOM, "musica", nome + ".wav")
    salvar_wav(buf, tmp)
    ogg = os.path.join(SOM, "musica", nome + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "3", ogg], check=True)
    os.remove(tmp)


def musicas():
    musica("primavera", ["C", "G", "Am", "F", "C", "G", "F", "G"], 96, "C", False, "pluck", "flauta", 11)
    musica("verao", ["G", "C", "G", "D", "Em", "C", "D", "G"], 108, "G", False, "marimba", "marimba", 22, densidade=0.7)
    musica("outono", ["Am", "F", "C", "G", "Am", "F", "G", "E"], 84, "A", True, "pluck", "flauta", 33)
    musica("inverno", ["Dm", "A#", "F", "C", "Dm", "A#", "C", "A"], 70, "D", True, "pad", "sino", 44, densidade=0.45)
    musica("mina", ["Em", "Em", "C", "B", "Em", "Em", "C", "B"], 62, "E", True, "pad", "sino", 55, densidade=0.3, oitava_mel=4, sem_melodia_a_cada=2)
    musica("casa", ["F", "C", "Dm", "A#", "F", "C", "A#", "C"], 76, "F", False, "pluck", "sino", 66, densidade=0.5)
    musica("festa", ["C", "F", "G", "C", "Am", "F", "G", "C"], 120, "C", False, "marimba", "flauta", 77, densidade=0.8)


if __name__ == "__main__":
    print("efeitos:", efeitos())
    musicas()
    print("músicas ok")
