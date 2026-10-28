<p align="center">
  <img src="assets/images/banner.png" alt="MT5 Forex Robots" width="100%">
</p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-MetaTrader%205-1f6feb">
  <img alt="Language" src="https://img.shields.io/badge/language-MQL5-2ea44f">
  
</p>


## Robots

| # | Robot | Strategy | Type | Platform | Docs |
|---|-------|----------|------|----------|------|
| 1 | **OCO Straddle Trail EA** | Breakout (or fade) straddle with OCO pending orders and an aggressive trailing stop | Short-term, pending orders | MT5 | [Read more](bots/01-oco-straddle-trail-ea/README.md) |

## Quick start

1. In MetaTrader 5 press **F4** to open MetaEditor, then **File → Open Data Folder**.
2. Copy the robot's `.mq5` file into `MQL5/Experts`.
3. Open it in MetaEditor and compile with **F7**.
4. Attach it to a chart and enable **Algo Trading**.

Full walkthrough with troubleshooting: [docs/INSTALLATION.md](docs/INSTALLATION.md).

## Repository layout

```
.
├── bots/
│   ├── 01-oco-straddle-trail-ea/    # Robot #1: source, README, images
│   └── _template/                   # README template for adding new robots
├── docs/
│   ├── INSTALLATION.md              # Install and troubleshooting
│   ├── BACKTESTING.md               # How to backtest and optimize properly
│   └── FAQ.md
├── assets/images/                   # Banner and social preview
├── .github/                         # Issue and pull request templates
├── CHANGELOG.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── DISCLAIMER.md
├── SECURITY.md
├── LICENSE
└── README.md
```

## Documentation

- [Installation guide](docs/INSTALLATION.md)
- [Backtesting guide](docs/BACKTESTING.md)
- [FAQ](docs/FAQ.md)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)


## License

Released under the [MIT License](LICENSE). The risk disclaimer in [DISCLAIMER.md](DISCLAIMER.md) applies to all use of this software.
