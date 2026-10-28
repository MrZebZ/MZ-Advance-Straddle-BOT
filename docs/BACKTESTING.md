# Backtesting Guide

Backtests help you understand how a robot behaves. They do **not** predict future results.

## Basic setup

1. Open the **Strategy Tester** in MT5 (Ctrl+R).
2. Select the Expert Advisor, symbol and period.
3. **Modeling:** choose **Every tick based on real ticks** for pending-order and trailing-stop strategies such as the OCO Straddle Trail EA. "Every tick" (generated) is less reliable for tight stops.
4. Set a realistic **deposit** and **leverage** matching your intended account.
5. Use **Delay** (for example 50 to 200 ms) to simulate execution latency.
6. Make sure the symbol's **spread** is realistic. Test with the broker's real spread, not zero.

## What to look at

- **Equity curve** shape, not just net profit.
- **Maximum drawdown** (balance and equity).
- **Profit factor**, **recovery factor**, **number of trades**.
- **Average win vs average loss**, and the longest losing streak.
- Behavior around news events and rollover (wide spreads).

## Avoid over-optimization

- Optimize on one period and **validate on a different period** (walk-forward or out-of-sample).
- Prefer **broad, stable parameter regions** over a single "best" combination.
- Keep the number of optimized parameters small.
- Be suspicious of very smooth, very high-return results.
- Re-test with higher spread and added slippage. If results collapse, the edge is probably too thin.

## Notes for the OCO Straddle Trail EA

- Short distances and stops mean **spread and commission are a large share of each trade**. Always test with real costs.
- Optimizing `InpDistancePoints`, `InpInitialSLPoints`, `InpTrailStartPoints` and `InpTrailDistancePoints` together can easily curve-fit. Change them one group at a time.
- `InpExpiryMinutes` and `InpCooldownSeconds` control how often straddles are re-armed, which affects trade count.

## Sharing results

When publishing results, include: symbol, period, modeling mode, spread/delay settings, all inputs, and a screenshot of the report. Save images under the robot's `images/` folder.
