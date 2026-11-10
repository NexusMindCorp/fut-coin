#!/usr/bin/env python3
"""
Pipeline reproduzivel de processamento de assets do FutCoin (FEAT-001).
Le exclusivamente de assets/_fonte/ (intacto) e gera os assets finais otimizados
para a resolucao base 640x360 (filtro Nearest, pixel art 16 bits).
"""

from __future__ import annotations

import argparse
import hashlib
import math
import os
from pathlib import Path
import sys
import tempfile

try:
    from PIL import Image, __version__ as versao_pillow
except ImportError:
    sys.exit("Pillow ausente. Instale assets/_fonte/requirements.txt no ambiente do pipeline.")

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DIR_FONTE = os.path.join(RAIZ, "assets", "_fonte")
DIR_ENTITIES = os.path.join(RAIZ, "assets", "sprites", "entities")
DIR_LEVELS = os.path.join(RAIZ, "assets", "levels")
DIR_HUD = os.path.join(RAIZ, "assets", "ui", "hud")
DIR_MENUS = os.path.join(RAIZ, "assets", "ui", "menus")
DIR_TIMES = os.path.join(RAIZ, "assets", "ui", "times")

VERSAO_PILLOW = "12.3.0"
TIMES = (
    "atletico_mineiro", "botafogo", "corinthians", "cruzeiro",
    "flamengo", "fluminense", "palmeiras", "sao_paulo", "vasco",
)
FONTES = (
    "campo_estadio.png", "pregos_prata_vermelho.png", "placar_banner.png",
    "tela_versus.png", "moeda_50_centavos.png", "menu_principal.png",
) + tuple(f"{time}.png" for time in TIMES)


def limpar_alfa_binario(im: Image.Image, limiar: int = 128) -> Image.Image:
    """Garante canal alfa estritamente binario (0 ou 255) e quantizacao 16-bit limpa."""
    rgba = im.convert("RGBA")
    r, g, b, a = rgba.split()
    r_q = r.point(lambda v: (v & 0xF8) | (v >> 5))
    g_q = g.point(lambda v: (v & 0xF8) | (v >> 5))
    b_q = b.point(lambda v: (v & 0xF8) | (v >> 5))
    a_bin = a.point(lambda v: 255 if v >= limiar else 0)
    return Image.merge("RGBA", (r_q, g_q, b_q, a_bin))


# ==============================================================================
# 1. MOEDA (28x28 px) + SPRITESHEETS (Brilho, Flip, Dourada)
# ==============================================================================
PALETA_PRATA = {
    "contorno":   (14, 14, 18, 255),
    "borda_hi":   (238, 238, 242, 255),
    "borda_mid":  (186, 184, 188, 255),
    "borda_shad": (96, 94, 100, 255),
    "sulco":      (42, 40, 46, 255),
    "face":       (158, 154, 158, 255),
    "listra_dk":  (82, 80, 86, 255),
    "listra_lt":  (198, 196, 200, 255),
    "txt_hi":     (246, 246, 250, 255),
    "txt_body":   (210, 208, 214, 255),
    "txt_out":    (24, 22, 28, 255),
}

PALETA_DOURADA = {
    "contorno":   (24, 14, 4, 255),
    "borda_hi":   (255, 246, 168, 255),
    "borda_mid":  (238, 190, 54, 255),
    "borda_shad": (148, 96, 16, 255),
    "sulco":      (78, 46, 8, 255),
    "face":       (214, 162, 36, 255),
    "listra_dk":  (132, 84, 14, 255),
    "listra_lt":  (246, 208, 82, 255),
    "txt_hi":     (255, 252, 204, 255),
    "txt_body":   (248, 218, 104, 255),
    "txt_out":    (48, 26, 4, 255),
}


def gerar_moeda_base(pal: dict) -> Image.Image:
    """Gera a moeda de 28x28 px sem o texto 'CENTAVOS', mantendo '50' e estrelas."""
    n = 28
    im = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    px = im.load()
    cx, cy = 13.5, 13.5

    for y in range(n):
        for x in range(n):
            d = math.hypot(x - cx, y - cy)
            if d > 13.42:
                continue
            elif d > 12.25:
                px[x, y] = pal["contorno"]
            elif d > 11.15:
                if x + y < 25:
                    px[x, y] = pal["borda_hi"]
                elif x + y > 30:
                    px[x, y] = pal["borda_shad"]
                else:
                    px[x, y] = pal["borda_mid"]
            elif d > 10.15:
                px[x, y] = pal["sulco"] if (x + y < 27) else pal["borda_shad"]
            else:
                if x + y * 0.65 < 16.2 and y < 21:
                    fase = (x + int(y * 0.65)) % 2
                    px[x, y] = pal["listra_dk"] if fase == 0 else pal["listra_lt"]
                else:
                    px[x, y] = pal["face"]

    # Ondas inferiores (derivadas do design da moeda de 50 centavos)
    ondas = [
        (9, 22, pal["listra_dk"]), (10, 21, pal["txt_hi"]), (11, 21, pal["txt_hi"]),
        (12, 21, pal["listra_lt"]), (13, 22, pal["txt_hi"]), (14, 22, pal["txt_hi"]),
        (15, 22, pal["listra_lt"]), (16, 21, pal["txt_hi"]), (17, 21, pal["listra_lt"]),
        (18, 20, pal["listra_lt"]), (19, 19, pal["listra_lt"]),
        (10, 22, pal["listra_dk"]), (11, 22, pal["listra_dk"]), (12, 22, pal["listra_dk"]),
        (13, 23, pal["listra_dk"]), (14, 23, pal["listra_dk"]), (15, 23, pal["listra_dk"]),
        (16, 22, pal["listra_dk"]),
    ]
    for wx, wy, cor in ondas:
        px[wx, wy] = cor

    # 3 estrelas na direita
    for sx, sy in [(21, 10), (19, 13), (20, 17)]:
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            if math.hypot(sx + dx - cx, sy + dy - cy) <= 10.15:
                px[sx + dx, sy + dy] = pal["listra_dk"]
        px[sx, sy] = pal["txt_hi"]

    # Glifo "50" centralizado verticalmente
    glifo_5 = [
        "11111",
        "11000",
        "11000",
        "11110",
        "00011",
        "00011",
        "00011",
        "11011",
        "01110",
    ]
    glifo_0 = [
        "01110",
        "11011",
        "11011",
        "11011",
        "11011",
        "11011",
        "11011",
        "11011",
        "01110",
    ]
    fg = set()
    for gy, linha in enumerate(glifo_5):
        for gx, ch in enumerate(linha):
            if ch == "1":
                fg.add((6 + gx, 9 + gy))
    for gy, linha in enumerate(glifo_0):
        for gx, ch in enumerate(linha):
            if ch == "1":
                fg.add((12 + gx, 9 + gy))

    for fx, fy in fg:
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                nx, ny = fx + dx, fy + dy
                if (nx, ny) not in fg and math.hypot(nx - cx, ny - cy) <= 10.4:
                    px[nx, ny] = pal["txt_out"]

    for fx, fy in fg:
        if (fx, fy - 1) not in fg or fy == 9:
            px[fx, fy] = pal["txt_hi"]
        else:
            px[fx, fy] = pal["txt_body"]

    return im


def gerar_sheet_brilho_moeda(moeda_base: Image.Image, cor_brilho: tuple) -> Image.Image:
    """Gera spritesheet de 8 quadros (224x28) com faixa de brilho diagonal passando."""
    n = 28
    quadros = 8
    sheet = Image.new("RGBA", (n * quadros, n), (0, 0, 0, 0))
    cx, cy = 13.5, 13.5

    for q in range(quadros):
        quadro = moeda_base.copy()
        if 1 <= q <= 6:
            px = quadro.load()
            centro_diag = -6 + q * 8.5
            for y in range(n):
                for x in range(n):
                    r, g, b, a = px[x, y]
                    if a == 0:
                        continue
                    # Preserva o contorno preto externo
                    if math.hypot(x - cx, y - cy) > 12.2:
                        continue
                    dist = abs((x + y) - centro_diag)
                    if dist <= 1.6:
                        # Brilho forte
                        px[x, y] = (
                            min(255, int(r * 0.35 + cor_brilho[0] * 0.65)),
                            min(255, int(g * 0.35 + cor_brilho[1] * 0.65)),
                            min(255, int(b * 0.35 + cor_brilho[2] * 0.65)),
                            255,
                        )
                    elif dist <= 3.2:
                        # Brilho secundario
                        px[x, y] = (
                            min(255, int(r * 0.65 + cor_brilho[0] * 0.35)),
                            min(255, int(g * 0.65 + cor_brilho[1] * 0.35)),
                            min(255, int(b * 0.65 + cor_brilho[2] * 0.35)),
                            255,
                        )
        sheet.paste(quadro, (q * n, 0))
    return sheet


def gerar_sheet_flip_moeda(moeda_base: Image.Image, pal: dict) -> Image.Image:
    """Gera spritesheet de 8 quadros (224x28) simulando giro (flip) da moeda com borda curva."""
    n = 28
    larguras = [28, 22, 14, 6, 4, 12, 22, 26]
    sheet = Image.new("RGBA", (n * len(larguras), n), (0, 0, 0, 0))

    for q, larg in enumerate(larguras):
        quadro = Image.new("RGBA", (n, n), (0, 0, 0, 0))
        comprimida = moeda_base.resize((larg, n), Image.Resampling.NEAREST)
        x0 = (n - larg) // 2
        # Nos quadros estreitos, desenha espessura metalica lateral seguindo a silhueta oval
        if larg <= 14:
            espessura = 2 if larg <= 6 else 1
            borda_3d = comprimida.copy()
            px_b = borda_3d.load()
            for y in range(n):
                for x in range(larg):
                    if px_b[x, y][3] == 0:
                        continue
                    if y <= 2 or y >= n - 3 or x == 0 or x == larg - 1:
                        px_b[x, y] = pal["contorno"]
                    else:
                        px_b[x, y] = pal["borda_hi"] if y < 14 else pal["borda_mid"]
            desloc = espessura if q < 4 else -espessura
            quadro.paste(borda_3d, (x0 + desloc, 0), borda_3d)
        quadro.paste(comprimida, (x0, 0), comprimida)
        sheet.paste(quadro, (q * n, 0))
    return sheet


def gerar_sheet_giro_2d_moeda(moeda_base: Image.Image, pal: dict) -> Image.Image:
    """Gera spritesheet de 8 quadros (224x28) com a moeda girando deitada no plano 2D (top-down),
    mantendo o anel externo e iluminacao fixos para nao serrilhar o circulo."""
    n = 28
    angulos = [0, 45, 90, 135, 180, 225, 270, 315]
    sheet = Image.new("RGBA", (n * len(angulos), n), (0, 0, 0, 0))
    cx, cy = 13.5, 13.5
    px_base = moeda_base.load()

    for q, ang in enumerate(angulos):
        if ang == 0:
            sheet.paste(moeda_base, (0, 0))
            continue
        quadro = moeda_base.copy()
        px_q = quadro.load()
        rad = math.radians(-ang)
        cos_a, sin_a = math.cos(rad), math.sin(rad)
        for y in range(n):
            for x in range(n):
                if math.hypot(x - cx, y - cy) <= 10.15:
                    dx, dy = x - cx, y - cy
                    sx = int(round(cx + dx * cos_a - dy * sin_a))
                    sy = int(round(cy + dx * sin_a + dy * cos_a))
                    sx = max(0, min(n - 1, sx))
                    sy = max(0, min(n - 1, sy))
                    if math.hypot(sx - cx, sy - cy) <= 10.15:
                        px_q[x, y] = px_base[sx, sy]
                    else:
                        px_q[x, y] = pal["face"]
        sheet.paste(quadro, (q * n, 0))
    return sheet


# ==============================================================================
# 2. PREGOS (12x12 px) + SPRITESHEETS DE COLISAO (4 quadros)
# ==============================================================================
def extrair_prego_12(im_crop: Image.Image, tom_aco: bool) -> Image.Image:
    """Extrai o prego na grade nativa de 12x12 px e remove fundo branco externo."""
    n = 12
    w, h = im_crop.size
    out = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    px_in = im_crop.load()
    px_out = out.load()

    for y in range(n):
        sy = int((y + 0.5) * h / n)
        for x in range(n):
            sx = int((x + 0.5) * w / n)
            r, g, b, a = px_in[sx, sy]
            px_out[x, y] = (r, g, b, 255 if a >= 128 else 0)

    # Flood-fill nos 4 cantos para limpar pixels brancos fora do contorno preto
    pilha = [(0, 0), (n - 1, 0), (0, n - 1), (n - 1, n - 1)]
    visitados = set()
    while pilha:
        cx, cy = pilha.pop()
        if (cx, cy) in visitados or not (0 <= cx < n and 0 <= cy < n):
            continue
        visitados.add((cx, cy))
        r, g, b, a = px_out[cx, cy]
        if a == 0 or (r > 200 and g > 200 and b > 200):
            px_out[cx, cy] = (0, 0, 0, 0)
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                pilha.append((cx + dx, cy + dy))

    if tom_aco:
        for y in range(n):
            for x in range(n):
                r, g, b, a = px_out[x, y]
                if a == 0:
                    continue
                lum = (r + g + b) / 3.0
                if lum < 35:
                    px_out[x, y] = (12, 14, 20, 255)
                elif lum > 230:
                    px_out[x, y] = (220, 232, 248, 255)
                else:
                    fator = 0.58
                    nr = int(max(28, min(180, lum * fator * 0.82)))
                    ng = int(max(34, min(195, lum * fator * 0.94)))
                    nb = int(max(46, min(220, lum * fator * 1.18)))
                    px_out[x, y] = (nr, ng, nb, 255)
    return out


def gerar_sheet_colisao_prego(prego_base: Image.Image) -> Image.Image:
    """Gera spritesheet de 4 quadros (48x12) com piscada e squash/stretch ao colidir."""
    n = 12
    sheet = Image.new("RGBA", (n * 4, n), (0, 0, 0, 0))
    # Quadro 0: normal
    sheet.paste(prego_base, (0, 0))

    # Quadro 1: flash claro intenso no impacto
    q1 = prego_base.copy()
    px1 = q1.load()
    for y in range(n):
        for x in range(n):
            r, g, b, a = px1[x, y]
            if a > 0 and (r + g + b) / 3.0 >= 35:
                px1[x, y] = (min(255, r + 95), min(255, g + 95), min(255, b + 95), 255)
    sheet.paste(q1, (n, 0))

    # Quadro 2: achatamento (12x10 centralizado) + brilho medio
    q2_base = prego_base.resize((12, 10), Image.Resampling.NEAREST)
    q2 = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    q2.paste(q2_base, (0, 1), q2_base)
    px2 = q2.load()
    for y in range(n):
        for x in range(n):
            r, g, b, a = px2[x, y]
            if a > 0 and (r + g + b) / 3.0 >= 35:
                px2[x, y] = (min(255, r + 45), min(255, g + 45), min(255, b + 45), 255)
    sheet.paste(q2, (n * 2, 0))

    # Quadro 3: rebote vertical (10x12 centralizado) retornando ao normal
    q3_base = prego_base.resize((10, 12), Image.Resampling.NEAREST)
    q3 = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    q3.paste(q3_base, (1, 0), q3_base)
    sheet.paste(q3, (n * 3, 0))

    return sheet


# ==============================================================================
# 3. CAMPO ESTENDIDO (1152x320) E TILESET DE 16x16 PX COM TILES ANIMADOS
# ==============================================================================
def processar_campo_e_tileset() -> tuple:
    """Gera o campo estendido (1152x320, gol ~72px) e o atlas de tiles 16x16 com animacoes."""
    im_c = limpar_alfa_binario(Image.open(os.path.join(DIR_FONTE, "campo_estadio.png")))

    # Reduzir abertura do gol na imagem fonte para resultar em ~72 px na altura final de 320 px
    im_mod = im_c.copy()
    gol_strip = im_c.crop((0, 326, 111, 650))
    gol_redim = gol_strip.resize((111, 260), Image.Resampling.NEAREST)
    parede_sup = im_c.crop((0, 250, 111, 282))
    parede_inf = im_c.crop((0, 690, 111, 722))
    im_mod.paste(parede_sup, (0, 326))
    im_mod.paste(gol_redim, (0, 358))
    im_mod.paste(parede_inf, (0, 618))

    y0, y1 = 65, 912
    fh = y1 - y0

    # Fatias horizontais livres do arco da grande area (x<=373) e do circulo central (x>=650):
    # Seg A: x = 15..376 (gol esquerdo + grande area + meia-lua completa)
    # Seg B: x = 376..615 (239 px: 1 pilar de parafuso + borda vermelha + grama limpa sem linhas verticais)
    # Seg C: x = 615..768 (153 px: 1 pilar + metade esquerda do circulo central ate o meio-campo)
    seg_a = im_mod.crop((15, y0, 376, y1))
    seg_b = im_mod.crop((376, y0, 615, y1))
    seg_c = im_mod.crop((615, y0, 768, y1))

    larg_esq = seg_a.width + 3 * seg_b.width + seg_c.width
    metade_esq = Image.new("RGBA", (larg_esq, fh), (0, 0, 0, 0))
    cx = 0
    metade_esq.paste(seg_a, (cx, 0)); cx += seg_a.width
    for _ in range(3):
        metade_esq.paste(seg_b, (cx, 0)); cx += seg_b.width
    metade_esq.paste(seg_c, (cx, 0))

    metade_dir = metade_esq.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    campo_bruto = Image.new("RGBA", (larg_esq * 2, fh), (0, 0, 0, 0))
    campo_bruto.paste(metade_esq, (0, 0))
    campo_bruto.paste(metade_dir, (larg_esq, 0))

    # Reamostrar para 1152x320 (exatos 72x20 tiles de 16x16 px)
    campo_final = campo_bruto.resize((1152, 320), Image.Resampling.NEAREST)

    # Construir atlas compacto de 128x128 px (8x8 tiles de 16x16):
    # - Linhas 0 a 3 (y=0..63): 32 tiles base canonicos (cantos, paredes, gols, linhas, grama)
    # - Linha 4 (y=64..79):  Borda LED vermelha sup (4q) + Pilar parafuso sup (4q)
    # - Linha 5 (y=80..95):  Borda LED vermelha inf (4q) + Pilar parafuso inf (4q)
    # - Linha 6 (y=96..111): Rede do gol esq (4q) + Rede do gol dir (4q)
    # - Linha 7 (y=112..127): Grama clara animada (4q) + Grama escura animada (4q)
    atlas = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    coords_base = [
        # Linha 0: Cantos superiores, bordas superiores, pilares, linha superior
        (16, 0), (32, 0), (176, 0), (240, 0), (560, 0), (960, 0), (1104, 0), (1120, 0),
        # Linha 1: Paredes laterais, linhas de fundo, grande area, meio-campo, circulo central
        (16, 48), (32, 48), (48, 48), (128, 80), (144, 144), (560, 48), (560, 144), (1120, 48),
        # Linha 2: Gols (superior, rede, inferior - esquerdo e direito) + marca do penalti
        (0, 112), (16, 112), (16, 144), (16, 192), (96, 144), (1120, 112), (1120, 144), (1120, 192),
        # Linha 3: Cantos inferiores, bordas inferiores, grama clara e escura limpa
        (16, 304), (32, 304), (176, 304), (240, 304), (320, 64), (320, 80), (1104, 304), (1120, 304),
    ]
    for idx, (tx, ty) in enumerate(coords_base):
        gx = (idx % 8) * 16
        gy = (idx // 8) * 16
        atlas.paste(campo_final.crop((tx, ty, tx + 16, ty + 16)), (gx, gy))

    # --- TILES ANIMADOS (4 quadros horizontais por animacao para TileSetAtlasSource) ---
    y_anim = 64

    # Animacao 1: Borda vermelha superior com luz correndo + parafuso pulsando (y = 16..32 e y = 0..16)
    tile_borda_sup = campo_final.crop((240, 16, 256, 32))
    tile_pilar_sup = campo_final.crop((176, 0, 192, 16))
    # Animacao 2: Borda vermelha inferior com luz correndo (y = 288..304 e y = 304..320)
    tile_borda_inf = campo_final.crop((240, 288, 256, 304))
    tile_pilar_inf = campo_final.crop((176, 304, 192, 320))

    def animar_luz_borda(tile_base: Image.Image, quadro: int) -> Image.Image:
        t = tile_base.copy()
        px = t.load()
        faixa_x = (quadro * 4) % 16
        for y in range(16):
            for x in range(16):
                r, g, b, a = px[x, y]
                if a == 0:
                    continue
                dist = min(abs(x - faixa_x), 16 - abs(x - faixa_x))
                if r > g + 35 and dist <= 3:
                    # Faixa vermelha de LED piscando em laranja/amarelo vivo
                    ganho = 95 if dist <= 1 else 50
                    px[x, y] = (min(255, r + ganho), min(255, g + ganho), min(255, b + ganho // 2), 255)
                elif r > 80 and g > 80 and b > 90 and dist <= 2:
                    # Reflexo metalico correndo na mureta/pilar
                    ganho = 55 if dist <= 1 else 28
                    px[x, y] = (min(255, r + ganho), min(255, g + ganho), min(255, b + ganho), 255)
        return t

    for q in range(4):
        atlas.paste(animar_luz_borda(tile_borda_sup, q), (q * 16, y_anim))
        atlas.paste(animar_luz_borda(tile_pilar_sup, q), ((4 + q) * 16, y_anim))
        atlas.paste(animar_luz_borda(tile_borda_inf, q), (q * 16, y_anim + 16))
        atlas.paste(animar_luz_borda(tile_pilar_inf, q), ((4 + q) * 16, y_anim + 16))

    # Animacao 3: Rede do gol ondulando (4 quadros para gol esquerdo e 4 para gol direito)
    tile_rede_esq = campo_final.crop((16, 144, 32, 160))
    tile_rede_dir = campo_final.crop((1120, 144, 1136, 160))

    def animar_rede(tile_base: Image.Image, quadro: int) -> Image.Image:
        t = tile_base.copy()
        px_in = tile_base.load()
        px_out = t.load()
        for y in range(16):
            desloc = 1 if ((y // 4 + quadro) % 4 == 1) else (-1 if ((y // 4 + quadro) % 4 == 3) else 0)
            for x in range(16):
                sx = max(0, min(15, x + desloc))
                r, g, b, a = px_in[sx, y]
                if quadro in (1, 3) and r > 180 and g > 180:
                    px_out[x, y] = (min(255, r + 25), min(255, g + 25), min(255, b + 30), a)
                else:
                    px_out[x, y] = (r, g, b, a)
        return t

    for q in range(4):
        atlas.paste(animar_rede(tile_rede_esq, q), (q * 16, y_anim + 32))
        atlas.paste(animar_rede(tile_rede_dir, q), ((4 + q) * 16, y_anim + 32))

    # Animacao 4: Grama com tufo balancando (4 quadros)
    tile_grama_clara = campo_final.crop((320, 64, 336, 80))
    tile_grama_escura = campo_final.crop((320, 80, 336, 96))

    def animar_grama(tile_base: Image.Image, quadro: int) -> Image.Image:
        t = tile_base.copy()
        px = t.load()
        dx = [0, 1, 0, -1][quadro]
        cor_tufo = (14, 92, 12, 255)
        cor_hi = (52, 178, 38, 255)
        cx, cy = 7 + dx, 8
        for ox, oy in [(-2, -1), (-1, 0), (0, 1), (1, 0), (2, -1)]:
            if 0 <= cx + ox < 16 and 0 <= cy + oy < 16:
                px[cx + ox, cy + oy] = cor_tufo
        if 0 <= cx < 16 and 0 <= cy - 1 < 16:
            px[cx, cy - 1] = cor_hi
        return t

    for q in range(4):
        atlas.paste(animar_grama(tile_grama_clara, q), (q * 16, y_anim + 48))
        atlas.paste(animar_grama(tile_grama_escura, q), ((4 + q) * 16, y_anim + 48))

    return campo_final, atlas


# ==============================================================================
# 4. UI: BANNER DO HUD, 9 BRASOES E TELA VERSUS
# ==============================================================================
def processar_ui() -> None:
    # 4.1 Banner do HUD (recorte exato + reducao para 320x44 px)
    im_b = limpar_alfa_binario(Image.open(os.path.join(DIR_FONTE, "placar_banner.png")))
    banner_crop = im_b.crop((28, 217, 2143, 511))
    banner_final = banner_crop.resize((320, 44), Image.Resampling.NEAREST)
    banner_final.save(os.path.join(DIR_HUD, "placar_banner.png"), optimize=True)

    # 4.2 9 Brasoes (grade nativa exata 48x48 px a partir de 2400x2400)
    for time in TIMES:
        im_t = limpar_alfa_binario(Image.open(os.path.join(DIR_FONTE, f"{time}.png")))
        im_48 = im_t.resize((48, 48), Image.Resampling.NEAREST)
        im_48.save(os.path.join(DIR_TIMES, f"{time}.png"), optimize=True)

    # 4.3 Tela Versus (640x360 px em snake_case)
    im_v = limpar_alfa_binario(Image.open(os.path.join(DIR_FONTE, "tela_versus.png")))
    versus_final = im_v.resize((640, 360), Image.Resampling.NEAREST)
    versus_final.save(os.path.join(DIR_MENUS, "tela_versus.png"), optimize=True)

    # 4.4 Menu principal (640x360 px, paleta reduzida para visual 16 bits)
    im_m = Image.open(os.path.join(DIR_FONTE, "menu_principal.png")).convert("RGB")
    menu_640 = im_m.resize((640, 360), Image.Resampling.BOX)
    menu_16 = menu_640.quantize(colors=48, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    menu_16.convert("RGB").save(os.path.join(DIR_MENUS, "menu_principal.png"), optimize=True)

def gerar_assets() -> None:
    # 1. Moedas
    moeda_prata = gerar_moeda_base(PALETA_PRATA)
    moeda_prata.save(os.path.join(DIR_ENTITIES, "moeda_50_centavos.png"), optimize=True)
    gerar_sheet_brilho_moeda(moeda_prata, (255, 255, 255)).save(
        os.path.join(DIR_ENTITIES, "moeda_brilho_sheet.png"), optimize=True
    )
    gerar_sheet_flip_moeda(moeda_prata, PALETA_PRATA).save(
        os.path.join(DIR_ENTITIES, "moeda_flip_sheet.png"), optimize=True
    )
    gerar_sheet_giro_2d_moeda(moeda_prata, PALETA_PRATA).save(
        os.path.join(DIR_ENTITIES, "moeda_giro_sheet.png"), optimize=True
    )

    moeda_ouro = gerar_moeda_base(PALETA_DOURADA)
    moeda_ouro.save(os.path.join(DIR_ENTITIES, "moeda_dourada.png"), optimize=True)
    gerar_sheet_brilho_moeda(moeda_ouro, (255, 255, 220)).save(
        os.path.join(DIR_ENTITIES, "moeda_dourada_sheet.png"), optimize=True
    )
    gerar_sheet_giro_2d_moeda(moeda_ouro, PALETA_DOURADA).save(
        os.path.join(DIR_ENTITIES, "moeda_dourada_giro_sheet.png"), optimize=True
    )

    # 2. Pregos
    im_p = Image.open(os.path.join(DIR_FONTE, "pregos_prata_vermelho.png")).convert("RGBA")
    prego_prata = extrair_prego_12(im_p.crop((607, 431, 759, 582)), tom_aco=True)
    prego_vermelho = extrair_prego_12(im_p.crop((776, 431, 929, 582)), tom_aco=False)
    prego_prata.save(os.path.join(DIR_ENTITIES, "prego_prata.png"), optimize=True)
    prego_vermelho.save(os.path.join(DIR_ENTITIES, "prego_vermelho.png"), optimize=True)
    gerar_sheet_colisao_prego(prego_prata).save(
        os.path.join(DIR_ENTITIES, "prego_prata_colisao_sheet.png"), optimize=True
    )
    gerar_sheet_colisao_prego(prego_vermelho).save(
        os.path.join(DIR_ENTITIES, "prego_vermelho_colisao_sheet.png"), optimize=True
    )

    # 3. Campo e Tileset
    campo_final, atlas_tiles = processar_campo_e_tileset()
    campo_final.save(os.path.join(DIR_LEVELS, "campo_estadio.png"), optimize=True)
    atlas_tiles.save(os.path.join(DIR_LEVELS, "campo_tileset.png"), optimize=True)

    # 4. UI
    processar_ui()


def conferir_fontes() -> dict[str, str]:
    """Confere as entradas antes de gravar qualquer arquivo de saida."""
    hashes: dict[str, str] = {}
    for nome in FONTES:
        caminho = Path(DIR_FONTE) / nome
        with Image.open(caminho) as imagem:
            imagem.verify()
        hashes[nome] = hashlib.sha256(caminho.read_bytes()).hexdigest()
    return hashes


def configurar_destinos(raiz_saida: Path) -> None:
    """Mantem a estrutura dos assets, protegendo originais e links simbolicos."""
    global DIR_ENTITIES, DIR_LEVELS, DIR_HUD, DIR_MENUS, DIR_TIMES
    fonte = Path(DIR_FONTE).resolve()
    destinos = [
        raiz_saida / "sprites" / "entities", raiz_saida / "levels",
        raiz_saida / "ui" / "hud", raiz_saida / "ui" / "menus",
        raiz_saida / "ui" / "times",
    ]
    # Examinar todos os caminhos antes de criar qualquer diretorio.
    for destino in destinos:
        resolvido = destino.resolve()
        if resolvido == fonte or fonte in resolvido.parents or resolvido in fonte.parents:
            raise ValueError("A saida nao pode conter ou sobrescrever assets/_fonte/.")
        # Um PNG de saida existente tambem pode ser um link para um original.
        if destino.exists():
            for caminho in destino.glob("*.png"):
                if caminho.is_symlink() or (caminho.is_file() and caminho.stat().st_nlink > 1):
                    raise ValueError(f"PNG de destino com link nao permitido: {caminho}")
    for destino in destinos:
        destino.mkdir(parents=True, exist_ok=True)
    DIR_ENTITIES, DIR_LEVELS, DIR_HUD, DIR_MENUS, DIR_TIMES = map(str, destinos)


def conferir_resultado(raiz_gerada: Path, referencia: Path) -> None:
    """Compara pixels decodificados; compressao PNG pode variar entre plataformas."""
    caminhos = sorted(raiz_gerada.rglob("*.png"))
    if len(caminhos) != 24:
        raise ValueError(f"Esperados 24 PNGs gerados; encontrados {len(caminhos)}.")
    divergencias: list[str] = []
    for caminho in caminhos:
        relativo = caminho.relative_to(raiz_gerada)
        atual = referencia / relativo
        if not atual.is_file():
            divergencias.append(f"ausente: {relativo}")
            continue
        with Image.open(caminho) as gerada, Image.open(atual) as existente:
            if (gerada.size != existente.size or gerada.mode != existente.mode
                    or gerada.tobytes() != existente.tobytes()):
                divergencias.append(f"pixels/dimensoes/modo diferentes: {relativo}")
    if divergencias:
        raise ValueError("Divergencias na reproducao:\n" + "\n".join(divergencias))
    print("24 PNGs conferidos: dimensoes, modo e pixels identicos aos assets atuais.")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Gera os assets do FutCoin ou confere sua reproducao sem sobrescreve-los."
    )
    opcoes = parser.add_mutually_exclusive_group()
    opcoes.add_argument("--saida", type=Path, help="Pasta alternativa que recebera a estrutura de assets.")
    opcoes.add_argument("--conferir", action="store_true", help="Gera em pasta temporaria e compara com assets/.")
    argumentos = parser.parse_args()
    try:
        if sys.version_info < (3, 10):
            raise ValueError("Use Python 3.10 ou superior no ambiente do pipeline.")
        if versao_pillow != VERSAO_PILLOW:
            raise ValueError(f"Use Pillow {VERSAO_PILLOW}; instale assets/_fonte/requirements.txt.")
        hashes_antes = conferir_fontes()
        if argumentos.conferir:
            with tempfile.TemporaryDirectory(prefix="futcoin-assets-") as temporaria:
                raiz_temporaria = Path(temporaria)
                configurar_destinos(raiz_temporaria)
                gerar_assets()
                conferir_resultado(raiz_temporaria, Path(RAIZ) / "assets")
        else:
            saida = (argumentos.saida or Path(RAIZ) / "assets").resolve()
            configurar_destinos(saida)
            gerar_assets()
            print(f"Assets gerados em {saida}")
        if conferir_fontes() != hashes_antes:
            raise ValueError("Os originais mudaram durante a execucao; revise antes de continuar.")
        print("14 originais preservados (SHA-256).")
    except (OSError, ValueError) as erro:
        parser.exit(1, f"Falha no pipeline: {erro}\n")


if __name__ == "__main__":
    main()
