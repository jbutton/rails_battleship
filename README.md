# Rails Battleship

A real-time, two-player Battleship game built with Rails 8 and Hotwire. Two people open the app, get matched, place their fleets, and take turns firing. Both screens update live over Action Cable, with no page reloads and no custom JavaScript framework.

## How a game works

1. **Pick a name.** No accounts; the player is kept in the session.
2. **Join a game.** Matchmaking either drops you into a waiting game or opens a new one and waits for an opponent.
3. **Place your ships.** Once two players are matched, both get a 10×10 grid and a 10-minute timer to place the standard fleet (Carrier 5, Battleship 4, Cruiser 3, Submarine 3, Destroyer 2). If the timer runs out, a background job places any remaining fleet at random.
4. **Battle.** Players alternate shots. Each shot comes back as a miss, hit, or sink and is pushed to both players right away. The game ends when one fleet is fully sunk.

## Technical highlights

- **Server-authoritative rules.** Turn order, shot validation, and win detection all run on the server. The opponent's board is sent as a redacted view (`Board#to_opponent_view`) so ship positions never reach the other client.
- **Service objects for game flow.** `app/services/game_play/` holds `MatchmakingService`, `ShipPlacementService` and `FireShotService`. Each runs inside a database transaction and returns a `{ success:, error: }` result to the controller.
- **Race-safe matchmaking.** Waiting games are claimed with a row lock (`Game.waiting.lock.first`), so two players joining at the same moment can't take the same seat.
- **Live updates with Turbo Streams.** Phase changes (matched → placing → playing → game over) and shot results are broadcast to per-player streams, so each player gets their own view of the shared game.
- **Timed fallback with Active Job.** `AutoPlaceShipsJob` is scheduled for the placement deadline and starts the game if both boards end up ready.
- **Placement validation in two places.** A Stimulus controller previews valid and invalid positions on hover, and the server re-checks length, bounds, overlap, and straight-line contiguity before saving.
- **Rails 8 defaults.** SQLite, Solid Queue, Solid Cable, Solid Cache, Propshaft, importmap, and a Kamal deploy config. No Node, Redis, or Postgres needed.

## Tech stack

| Layer      | Choice                                             |
|------------|----------------------------------------------------|
| Language   | Ruby 3.4.7                                         |
| Framework  | Rails 8.1                                          |
| Frontend   | Hotwire (Turbo Streams + Stimulus), importmap      |
| Realtime   | Action Cable (async in dev, Solid Cable in prod)   |
| Jobs       | Active Job (Solid Queue in prod)                   |
| Database   | SQLite                                             |
| Deploy     | Docker + Kamal                                     |
| CI         | GitHub Actions: Brakeman, bundler-audit, importmap audit, RuboCop |

## Domain model

```
Player ──< Game >── Player          a Game has player1, player2, current_turn_player and winner
             │
             ├──< Board (one per player)   10×10 grid + ship list, stored as JSON
             └──< Shot                     x, y, shooter, target, result (miss | hit | sink)
```

A game moves through `waiting_for_players → placing_ships → in_progress → finished`.

## Running locally

Requires Ruby 3.4.7 (see `.ruby-version`).

```bash
git clone https://github.com/jbutton/rails_battleship.git
cd rails_battleship
bin/setup        # installs gems, prepares the database, starts the server
```

Or step by step:

```bash
bundle install
bin/rails db:prepare
bin/dev          # http://localhost:3000
```

To play against yourself, open the app in two separate browser sessions (for example, a normal window and a private window), enter a different name in each, and click join in both.

## Project layout

```
app/
  models/            Game, Player, Board (grid + ship rules), Shot
  services/game_play/ matchmaking, ship placement, firing
  jobs/              AutoPlaceShipsJob (placement timeout)
  javascript/controllers/
                     ship_placement, battleship_board, timer (Stimulus)
  views/games/       one partial per game phase, swapped via Turbo Streams
```

## Known limitations

- Manual placement is horizontal only. The rotate control isn't wired up yet, though auto-placement uses both orientations.
- Players are session-based, so closing the browser loses your identity.
- The test suite is still mostly generator scaffolding and needs real model and service tests.
