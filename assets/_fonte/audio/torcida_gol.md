# Fonte da torcida de gol

- Autor: misjoc.
- Obra: Small crowd cheering, Freesound 400590.
- Página: https://freesound.org/people/misjoc/sounds/400590/
- Licença: CC0 — https://creativecommons.org/publicdomain/zero/1.0/
- Fonte baixada em 12/11/2026: prévia pública HQ https://cdn.freesound.org/previews/400/400590_3372256-hq.mp3 (5,66 s), preservada em `torcida_misjoc_400590_hq.mp3`.
- Descrição do autor: cerca de 300 pessoas comemorando em um concerto na Hungria. Não é gravação de locução de gol.

Derivado para o jogo, com FFmpeg já disponível no ambiente (sem dependência em runtime):

```powershell
ffmpeg -hide_banner -nostdin -y -i assets/_fonte/audio/torcida_misjoc_400590_hq.mp3 -t 2.4 -af 'volume=9dB,afade=t=in:st=0:d=0.03,afade=t=out:st=1.75:d=0.65,alimiter=limit=0.7:level=false' -ar 44100 -ac 2 -codec:a libmp3lame -b:a 192k assets/sounds/sfx/torcida_gol.mp3
```
