# FAQ

**Is this profitable?**
There is no guarantee of profit. Results depend on symbol, broker costs, execution and market conditions. Test on demo and in the Strategy Tester before risking real money.

**Which account type should I use?**
Both work, but behavior differs slightly when both straddle orders fill nearly at once. On a hedging account you may briefly hold both positions; on a netting account they offset. See the robot's *Known limitations*.

**What does "points" mean? Is it pips?**
A point is the smallest price increment. On 5-digit brokers, 10 points = 1 pip. Inputs for this repo's robots are in points.

**Which symbols and timeframes?**
Start with a liquid major pair with a low spread. The OCO Straddle Trail EA works on ticks, so the chart timeframe has little effect.

**The EA is attached but nothing happens.**
Check that Algo Trading is enabled (green), the market is open, and your time, spread and daily-limit settings are not blocking new orders. Read the **Experts** tab.

**Orders are rejected by my broker.**
Common causes: stop distance below the broker's minimum, unsupported order expiry, or trading disabled for the symbol. The EA enforces the broker's minimum stop level and retries without expiry once.

**Can I run it on several pairs?**
Yes, attach it to each symbol's chart. Orders are identified by symbol and magic number.

**Can I run several robots from this repo together?**
Yes. Give each robot a **unique magic number** and keep total risk in mind.

**Do I need a VPS?**
Not required, but the EA only trails stops while MT5 is running and receiving ticks. A VPS avoids interruptions.

**Does it work on MT4?**
No. These robots are written in MQL5 for MetaTrader 5.

**How do I report a bug?**
Open an issue with your MT5 build, broker, symbol, inputs and the Experts-tab log.
