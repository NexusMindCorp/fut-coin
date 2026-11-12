# Apito final — derivado do som aprovado

Fonte: `assets/sounds/sfx/start_sound.mp3`, já presente e aprovado pelo usuário. Arquivo original preservado byte a byte. Origem/atribuição geral Pixabay mantida; mapeamento individual ao autor ainda pendente, conforme inventário de créditos. Nenhuma nova gravação externa.

Preparação: três sopros de 0,6 s, recortados da região ativa (0,28–0,88 s) do arquivo original, com pausa de 0,12 s após cada um e fades curtos. Pitch original, estéreo, 44,1 kHz, MP3 192 kb/s, duração 2,16 s. FFmpeg usado somente offline, já disponível no ambiente.

```powershell
ffmpeg -hide_banner -nostdin -y -i assets/sounds/sfx/start_sound.mp3 -filter_complex '[0:a]atrim=start=0.28:end=0.88,asetpts=PTS-STARTPTS,afade=t=in:st=0:d=0.005,afade=t=out:st=0.57:d=0.03,apad=pad_dur=0.12,asplit=3[a][b][c];[a][b][c]concat=n=3:v=0:a=1[final]' -map '[final]' -ar 44100 -ac 2 -codec:a libmp3lame -b:a 192k assets/sounds/sfx/apito_final.mp3
```
