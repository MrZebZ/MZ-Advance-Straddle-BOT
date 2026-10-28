# Installation Guide

## Requirements

- MetaTrader 5 (desktop). The code uses `input group`, so use a reasonably recent build.
- A **demo** account to start with.
- A broker that allows Expert Advisors and pending orders on your symbol.

## Install a robot

1. Open MetaTrader 5.
2. Press **F4** to open MetaEditor.
3. In MetaEditor choose **File → Open Data Folder**.
4. Go to `MQL5/Experts` and copy the robot's `.mq5` file there.
5. Back in MetaEditor, open the file and press **F7** to compile. The *Errors* tab should show `0 errors`.
6. In MT5, open the **Navigator** (Ctrl+N), right-click **Expert Advisors** and choose **Refresh**.
7. Drag the robot onto a chart.

## Enable trading

1. In the EA's **Common** tab tick **Allow Algo Trading**.
2. Make sure the **Algo Trading** button in the main toolbar is **green**.
3. Open the **Inputs** tab and review the parameters before clicking OK.

A smiley face in the top-right of the chart means the EA is running. A sad face or a red icon means trading is not allowed.

## Verify it works

- Check the **Experts** tab (Toolbox, Ctrl+T) for messages from the EA.
- Robot #1 also prints its status in the chart's top-left corner.

## Troubleshooting

| Symptom | Likely cause and fix |
|---------|----------------------|
| EA not in Navigator | Wrong folder, or Navigator not refreshed. Check `MQL5/Experts`, then Refresh. |
| Compile errors | Use the latest file version and a current MT5 build. Do not edit the `#include` lines. |
| `BLOCKED: click the AutoTrading button` | Toolbar Algo Trading button is off. Click it so it turns green. |
| `BLOCKED: tick 'Allow Algo Trading'` | Enable it in the EA's Common tab. |
| `ORDER REJECTED by broker` | Check the retcode in the Experts tab. Often an invalid stop distance, market closed, or unsupported expiry. |
| Nothing happens | Check the time filter, spread filter and daily limits in the Inputs tab. Confirm the market is open. |
| Orders appear on one symbol only | Attach the EA to each symbol's chart you want to trade. |

## Running 24/5

Many traders run EAs on a **VPS** (MT5: View → Toolbox → Market → Virtual Hosting, or a third-party provider) so the platform keeps running and receives ticks without interruption.
