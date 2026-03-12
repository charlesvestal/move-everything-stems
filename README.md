# Stem Separation for Move Everything

Separate audio files into individual stems (drums, vocals, accompaniment) directly on your Ableton Move using SpleeterRT.

## Features

- 3-stem separation: drums, vocals, accompaniment
- ~0.5x realtime processing speed
- Stem review with selective saving — keep all or pick individual stems
- Output saved as WAV files to UserLibrary/Stems/

## Prerequisites

- [Move Everything](https://github.com/charlesvestal/move-everything) installed on your Ableton Move
- SSH access enabled: http://move.local/development/ssh

## Install

### Via Module Store (Recommended)

1. Launch Move Everything on your Move
2. Select **Module Store** from the main menu
3. Navigate to **Tools** > **Stem Separation**
4. Select **Install**

### Build from Source

```bash
git clone https://github.com/charlesvestal/move-everything-stems
cd move-anything-stems
./scripts/build.sh
./scripts/install.sh
```

## Usage

1. Open the Tools menu (Shift+Vol+Step13)
2. Select **Stem Separation**
3. Browse and select a WAV file
4. Confirm to start processing
5. Review the produced stems — all are selected by default
6. Push **Save All** to keep everything, or deselect stems you don't want
7. Stems are saved to `UserLibrary/Stems/<filename>/`

## Output

Each separation produces three WAV files:
- `drums.wav` — percussion and drum hits
- `vocals.wav` — vocal content
- `accompaniment.wav` — everything else (bass, synths, guitars, etc.)

## Credits

- **SpleeterRT engine**: Real-time stem separation
- **Move Everything framework**: [Charles Vestal](https://github.com/charlesvestal/move-everything)

## License

MIT License — See [LICENSE](LICENSE)

## AI Assistance Disclaimer

This module is part of Move Everything and was developed with AI assistance, including Claude, Codex, and other AI assistants.

All architecture, implementation, and release decisions are reviewed by human maintainers.
AI-assisted content may still contain errors, so please validate functionality, security, and license compatibility before production use.
