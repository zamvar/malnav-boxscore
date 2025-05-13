// ignore_for_file: no_default_cases, use_if_null_to_convert_nulls_to_bools, prefer_int_literals, unnecessary_raw_strings

import 'package:flutter/material.dart';
import 'package:score_board/app/commons/models/player_model.dart';

enum PrimaryAction {
  shotAttempt,
  freeThrow,
  foulCommitted,
  turnover,
  rebound,
  substitution,
  timeout
}

// Enums for sub-flows
enum ShotAttemptStep { type, outcome, details }

enum FoulCommittedStep { type, details }

enum TurnoverStep { type, details }

enum SubstitutionStep { direction, playerSelect }
// Removed FreeThrowStep as it's not currently used for a multi-step UI

// Main Modal Widget
class GameLogEntryModal extends StatefulWidget {

  const GameLogEntryModal({
    required this.playerInFocus, required this.gameQuarter, required this.gameClock, required this.playerInFocusTeamRoster, required this.opponentTeamRoster, required this.allPlayersOnCourt, required this.onLogConfirm, super.key,
  });
  final Player playerInFocus;
  final String gameQuarter;
  final String gameClock;
  // Full roster of the team to which playerInFocus belongs
  final List<Player> playerInFocusTeamRoster;
  // Full roster of the opposing team
  final List<Player> opponentTeamRoster;
  // List of all players currently on the court (from both teams)
  final List<Player> allPlayersOnCourt;
  final Function(Map<String, dynamic> logData) onLogConfirm;

  @override
  State<GameLogEntryModal> createState() => _GameLogEntryModalState();
}

class _GameLogEntryModalState extends State<GameLogEntryModal> {
  PrimaryAction? _selectedPrimaryAction;
  Map<String, dynamic> _currentLogData = {};

  // State for multi-step flows
  ShotAttemptStep _shotAttemptStep = ShotAttemptStep.type;
  FoulCommittedStep _foulCommittedStep = FoulCommittedStep.type;
  TurnoverStep _turnoverStep = TurnoverStep.type;
  SubstitutionStep _substitutionStep = SubstitutionStep.direction;
  // Removed _freeThrowStep state variable

  // --- Temporary selections for details ---
  String? _saPointType;
  String? _saOutcome;
  String? _saDetailType;
  Player? _saAssistingPlayer;
  Player? _saBlockingPlayer;
  String? _fcType;
  Player? _fcFouledPlayer;
  bool _fcIsShootingFoul = false;
  int? _fcFtsAwarded;
  bool? _ftIsMade;
  int _ftAttemptNumber = 1;
  int _ftTotalAttempts = 1;
  String? _toType;
  Player? _toStolenByPlayer;
  String? _rbType;
  String? _subDirection;
  Player? _subOtherPlayer;

  @override
  void initState() {
    super.initState();
    _resetSelectionsAndLogData();
  }

  void _resetSelectionsAndLogData() {
    setState(() {
      _saPointType = null;
      _saOutcome = null;
      _saDetailType = null;
      _saAssistingPlayer = null;
      _saBlockingPlayer = null;
      _fcType = null;
      _fcFouledPlayer = null;
      _fcIsShootingFoul = false;
      _fcFtsAwarded = null;
      _ftIsMade = null;
      _ftAttemptNumber = 1;
      _ftTotalAttempts = 1;
      _toType = null;
      _toStolenByPlayer = null;
      _rbType = null;
      _subDirection = null;
      _subOtherPlayer = null;

      _shotAttemptStep = ShotAttemptStep.type;
      _foulCommittedStep = FoulCommittedStep.type;
      _turnoverStep = TurnoverStep.type;
      _substitutionStep = SubstitutionStep.direction;
      // No need to reset _freeThrowStep

      _currentLogData = {
        'timestamp': DateTime.now().toIso8601String(),
        'quarter': widget.gameQuarter,
        'gameTime': widget.gameClock,
        'player': {
          'playerId': widget.playerInFocus.id,
          'playerName': widget.playerInFocus.name,
          'jerseyNumber': widget.playerInFocus.jerseyNumber,
        },
        'teamId': widget.playerInFocus.teamId,
        'points': 0,
        'details': {},
      };
    });
  }

  void _selectPrimaryAction(PrimaryAction action) {
    setState(() {
      _selectedPrimaryAction = action;
      _resetSelectionsAndLogData();
    });
  }

  Widget _buildPrimaryActionButtons() {
    final actions = [
      {
        'label': 'Shot Attempt',
        'action': PrimaryAction.shotAttempt,
        'icon': Icons.sports_basketball_outlined,
      },
      {
        'label': 'Free Throw',
        'action': PrimaryAction.freeThrow,
        'icon': Icons.adjust,
      },
      {
        'label': 'Foul Committed',
        'action': PrimaryAction.foulCommitted,
        'icon': Icons.sports,
      },
      {
        'label': 'Turnover',
        'action': PrimaryAction.turnover,
        'icon': Icons.sync_problem_outlined,
      },
      {
        'label': 'Rebound',
        'action': PrimaryAction.rebound,
        'icon': Icons.replay_circle_filled_outlined,
      },
      {
        'label': 'Substitution',
        'action': PrimaryAction.substitution,
        'icon': Icons.swap_horiz_outlined,
      },
      {
        'label': 'Timeout',
        'action': PrimaryAction.timeout,
        'icon': Icons.timer_outlined,
      },
    ];
    return Wrap(
      spacing: 10.0, // Horizontal space between items
      runSpacing: 10.0, // Vertical space between lines/runs
      alignment: WrapAlignment.center,
      children: actions.map((item) {
        return ElevatedButton.icon(
          icon: Icon(item['icon'] as IconData?, size: 18),
          label: Text(item['label']! as String),
          onPressed: () =>
              _selectPrimaryAction(item['action']! as PrimaryAction),
          style: ElevatedButton.styleFrom(
            minimumSize:
                const Size(130, 40), // Ensure buttons have a decent tap target
            textStyle: const TextStyle(fontSize: 13),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            // alignment: Alignment.centerLeft // This might make buttons uneven if text length varies
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayerSelector(
    String title,
    List<Player> players,
    Player? selectedPlayer,
    ValueChanged<Player?> onChanged, {
    String? hint,
    bool allowNone = false,
  }) {
    final List<DropdownMenuItem<Player>> items = players
        .map(
          (player) => DropdownMenuItem(
            value: player,
            child: Text(player.toString(), overflow: TextOverflow.ellipsis),
          ),
        )
        .toList();
    if (allowNone) {
      items.insert(
        0,
        DropdownMenuItem(value: null, child: Text(hint ?? 'None')),
      );
    }
    return DropdownButtonFormField<Player>(
      decoration: InputDecoration(
        labelText: title,
        border: const OutlineInputBorder(),
        hintText: hint ?? 'Select...',
      ),
      value: selectedPlayer,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
    );
  }

  Widget _buildShotAttemptDetails() {
    if (_shotAttemptStep == ShotAttemptStep.type) {
      return Column(
        children: [
          const Text(
            'Shot Point Type:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                child: const Text('2-Point'),
                onPressed: () => setState(() {
                  _saPointType = '2PT';
                  _shotAttemptStep = ShotAttemptStep.outcome;
                }),
              ),
              ElevatedButton(
                child: const Text('3-Point'),
                onPressed: () => setState(() {
                  _saPointType = '3PT';
                  _shotAttemptStep = ShotAttemptStep.outcome;
                }),
              ),
            ],
          ),
        ],
      );
    } else if (_shotAttemptStep == ShotAttemptStep.outcome) {
      return Column(
        children: [
          Text(
            'Outcome for $_saPointType:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                child: Text('MADE (${_saPointType == "2PT" ? 2 : 3} PTS)'),
                onPressed: () => setState(() {
                  _saOutcome = 'MADE';
                  _shotAttemptStep = ShotAttemptStep.details;
                }),
              ),
              ElevatedButton(
                child: const Text('MISSED'),
                onPressed: () => setState(() {
                  _saOutcome = 'MISSED';
                  _shotAttemptStep = ShotAttemptStep.details;
                }),
              ),
            ],
          ),
          TextButton(
            onPressed: () =>
                setState(() => _shotAttemptStep = ShotAttemptStep.type),
            child: const Text('Back to Shot Type'),
          ),
        ],
      );
    } else if (_shotAttemptStep == ShotAttemptStep.details) {
      final List<String> shotDetailsOptions = (_saPointType == '2PT')
          ? ['Layup', 'Jumpshot', 'Dunk', 'Tip-in', 'Other']
          : ['Catch & Shoot', 'Pull-up', 'Corner', 'Step-back'];
      return Column(
        children: [
          Text(
            'Details for $_saPointType $_saOutcome:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Specific Shot Detail',
              border: OutlineInputBorder(),
            ),
            value: _saDetailType,
            items: shotDetailsOptions
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (val) => setState(() => _saDetailType = val),
            validator: (val) => val == null ? 'Select shot detail' : null,
          ),
          if (_saOutcome == 'MADE') ...[
            const SizedBox(height: 10),
            _buildPlayerSelector(
              'Assisted By (Optional)',
              widget.playerInFocusTeamRoster
                  .where((p) => p.id != widget.playerInFocus.id)
                  .toList(),
              _saAssistingPlayer,
              (p) => setState(() => _saAssistingPlayer = p),
              allowNone: true,
              hint: 'None (Unassisted)',
            ),
          ],
          if (_saOutcome == 'MISSED') ...[
            const SizedBox(height: 10),
            _buildPlayerSelector(
              'Blocked By (Optional)',
              widget.opponentTeamRoster,
              _saBlockingPlayer,
              (p) => setState(() => _saBlockingPlayer = p),
              allowNone: true,
              hint: 'None (Not Blocked)',
            ),
          ],
          TextButton(
            onPressed: () =>
                setState(() => _shotAttemptStep = ShotAttemptStep.outcome),
            child: const Text('Back to Outcome'),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFoulDetails() {
    final List<String> foulTypes = [
      'Personal',
      'Offensive',
      'Technical',
      'Flagrant 1',
      'Flagrant 2',
    ];
    if (_foulCommittedStep == FoulCommittedStep.type) {
      return Column(
        children: [
          const Text('Foul Type:',
              style: TextStyle(fontWeight: FontWeight.bold),),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Foul Type',
              border: OutlineInputBorder(),
            ),
            value: _fcType,
            items: foulTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (val) => setState(() {
              _fcType = val;
              _foulCommittedStep = FoulCommittedStep.details;
            }),
            validator: (val) => val == null ? 'Select foul type' : null,
          ),
        ],
      );
    } else if (_foulCommittedStep == FoulCommittedStep.details) {
      final List<Player> possibleFouledPlayers = widget.allPlayersOnCourt
          .where((p) => p.id != widget.playerInFocus.id)
          .toList();

      return Column(
        children: [
          Text(
            'Details for $_fcType Foul:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          _buildPlayerSelector(
            'Fouled Player (Optional)',
            possibleFouledPlayers,
            _fcFouledPlayer,
            (p) => setState(() => _fcFouledPlayer = p),
            allowNone: true,
            hint: 'No specific player / Non-contact',
          ),
          if (_fcType == 'Personal' ||
              _fcType == 'Flagrant 1' ||
              _fcType == 'Flagrant 2') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Shooting Foul?'),
                Switch(
                  value: _fcIsShootingFoul,
                  onChanged: (val) => setState(() => _fcIsShootingFoul = val),
                ),
              ],
            ),
            if (_fcIsShootingFoul)
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'FTs Awarded',
                  border: OutlineInputBorder(),
                ),
                value: _fcFtsAwarded,
                items: [1, 2, 3]
                    .map(
                      (n) => DropdownMenuItem(
                        value: n,
                        child: Text('$n FT${n > 1 ? "s" : ""}'),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _fcFtsAwarded = val),
                validator: (val) => _fcIsShootingFoul && val == null
                    ? 'Select FTs awarded'
                    : null,
              ),
          ],
          TextButton(
            onPressed: () =>
                setState(() => _foulCommittedStep = FoulCommittedStep.type),
            child: const Text('Back to Foul Type'),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFreeThrowDetails() {
    return Column(
      children: [
        Text(
          'Free Throw for ${widget.playerInFocus.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Attempt: '),
            SizedBox(
              width: 50,
              child: TextField(
                controller:
                    TextEditingController(text: _ftAttemptNumber.toString()),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (val) => _ftAttemptNumber = int.tryParse(val) ?? 1,
              ),
            ),
            const Text(' of '),
            SizedBox(
              width: 50,
              child: TextField(
                controller:
                    TextEditingController(text: _ftTotalAttempts.toString()),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (val) => _ftTotalAttempts = int.tryParse(val) ?? 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text('Outcome:'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              child: const Text('MADE (1 PT)'),
              onPressed: () => setState(() => _ftIsMade = true),
            ),
            ElevatedButton(
              child: const Text('MISSED'),
              onPressed: () => setState(() => _ftIsMade = false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReboundDetails() {
    return Column(
      children: [
        Text(
          'Rebound by ${widget.playerInFocus.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text('Rebound Type:'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              child: const Text('Offensive'),
              onPressed: () => setState(() => _rbType = 'OFFENSIVE'),
            ),
            ElevatedButton(
              child: const Text('Defensive'),
              onPressed: () => setState(() => _rbType = 'DEFENSIVE'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTurnoverDetails() {
    final List<String> turnoverTypes = [
      'Bad Pass',
      'Lost Ball Dribble',
      'Traveling',
      '3 Seconds',
      '8 Seconds',
      'Shot Clock Violation',
      'Offensive Foul',
      'Out of Bounds',
      'Other',
    ];
    if (_turnoverStep == TurnoverStep.type) {
      return Column(
        children: [
          Text(
            'Turnover by ${widget.playerInFocus.name}:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Turnover Type',
              border: OutlineInputBorder(),
            ),
            value: _toType,
            items: turnoverTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (val) => setState(() {
              _toType = val;
              _turnoverStep = TurnoverStep.details;
            }),
            validator: (val) => val == null ? 'Select turnover type' : null,
          ),
        ],
      );
    } else if (_turnoverStep == TurnoverStep.details) {
      return Column(
        children: [
          Text(
            'Details for $_toType:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          _buildPlayerSelector(
            'Stolen By (Optional)',
            widget.opponentTeamRoster,
            _toStolenByPlayer,
            (p) => setState(() => _toStolenByPlayer = p),
            allowNone: true,
            hint: 'None (Not Stolen)',
          ),
          TextButton(
            onPressed: () => setState(() => _turnoverStep = TurnoverStep.type),
            child: const Text('Back to Turnover Type'),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSubstitutionDetails() {
    if (_substitutionStep == SubstitutionStep.direction) {
      return Column(
        children: [
          Text(
            'Substitution for ${widget.playerInFocus.name}:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                child: const Text('Player ENTERING'),
                onPressed: () => setState(() {
                  _subDirection = 'IN';
                  _substitutionStep = SubstitutionStep.playerSelect;
                }),
              ),
              ElevatedButton(
                child: const Text('Player LEAVING'),
                onPressed: () => setState(() {
                  _subDirection = 'OUT';
                  _substitutionStep = SubstitutionStep.playerSelect;
                }),
              ),
            ],
          ),
        ],
      );
    } else if (_substitutionStep == SubstitutionStep.playerSelect) {
      final String title = _subDirection == 'IN'
          ? 'Replacing Whom (On Court)?'
          : 'Replaced By Whom (On Bench)?';
      List<Player> selectablePlayers;

      if (_subDirection == 'IN') {
        selectablePlayers = widget.playerInFocusTeamRoster
            .where(
              (p) =>
                  p.id != widget.playerInFocus.id &&
                  widget.allPlayersOnCourt.any(
                    (onCourt) =>
                        onCourt.id == p.id &&
                        onCourt.teamId == widget.playerInFocus.teamId,
                  ),
            )
            .toList();
      } else {
        selectablePlayers = widget.playerInFocusTeamRoster
            .where(
              (p) =>
                  p.id != widget.playerInFocus.id &&
                  !widget.allPlayersOnCourt.any(
                    (onCourt) =>
                        onCourt.id == p.id &&
                        onCourt.teamId == widget.playerInFocus.teamId,
                  ),
            )
            .toList();
      }

      return Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          _buildPlayerSelector(
            'Select Player',
            selectablePlayers,
            _subOtherPlayer,
            (p) => setState(() => _subOtherPlayer = p),
            hint: 'Select Teammate',
          ),
          TextButton(
            onPressed: () => setState(
              () => _substitutionStep = SubstitutionStep.direction,
            ),
            child: const Text('Back to Direction'),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTimeoutDetails() {
    return Column(
      children: [
        Text(
          'Timeout called by ${widget.playerInFocus.teamId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text('Confirm timeout? (Further details like type can be added)'),
      ],
    );
  }

  Widget _buildDetailsSection() {
    switch (_selectedPrimaryAction) {
      case PrimaryAction.shotAttempt:
        return _buildShotAttemptDetails();
      case PrimaryAction.foulCommitted:
        return _buildFoulDetails();
      case PrimaryAction.freeThrow:
        return _buildFreeThrowDetails();
      case PrimaryAction.rebound:
        return _buildReboundDetails();
      case PrimaryAction.turnover:
        return _buildTurnoverDetails();
      case PrimaryAction.substitution:
        return _buildSubstitutionDetails();
      case PrimaryAction.timeout:
        return _buildTimeoutDetails();
      default:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Select an action above to add details.',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        );
    }
  }

  void _confirmLogEntry() {
    final Map<String, dynamic> finalLog = Map.from(_currentLogData);
    final Map<String, dynamic> details = {};

    switch (_selectedPrimaryAction) {
      case PrimaryAction.shotAttempt:
        finalLog['actionType'] =
            _saOutcome == 'MADE' ? 'FIELD_GOAL_MADE' : 'FIELD_GOAL_MISSED';
        finalLog['points'] =
            _saOutcome == 'MADE' ? (_saPointType == '3PT' ? 3 : 2) : 0;
        details['shotType'] = _saDetailType;
        if (_saOutcome == 'MADE' && _saAssistingPlayer != null) {
          details['isAssist'] = true;
          details['assistingPlayer'] = {
            'playerId': _saAssistingPlayer!.id,
            'playerName': _saAssistingPlayer!.name,
            'jerseyNumber': _saAssistingPlayer!.jerseyNumber,
          };
        }
        if (_saOutcome == 'MISSED' && _saBlockingPlayer != null) {
          details['isBlock'] = true;
          details['blockingPlayer'] = {
            'playerId': _saBlockingPlayer!.id,
            'playerName': _saBlockingPlayer!.name,
            'jerseyNumber': _saBlockingPlayer!.jerseyNumber,
          };
        }
      case PrimaryAction.freeThrow:
        finalLog['actionType'] = 'FREE_THROW_ATTEMPT';
        finalLog['points'] = _ftIsMade == true ? 1 : 0;
        details['isMade'] = _ftIsMade;
        details['attemptNumber'] = _ftAttemptNumber;
        details['totalAttempts'] = _ftTotalAttempts;
      case PrimaryAction.foulCommitted:
        finalLog['actionType'] = 'FOUL_COMMITTED';
        details['foulType'] = _fcType;
        if (_fcFouledPlayer != null) {
          details['fouledPlayer'] = {
            'playerId': _fcFouledPlayer!.id,
            'playerName': _fcFouledPlayer!.name,
            'jerseyNumber': _fcFouledPlayer!.jerseyNumber,
          };
        }
        details['isShootingFoul'] = _fcIsShootingFoul;
        if (_fcIsShootingFoul && _fcFtsAwarded != null) {
          details['ftsAwarded'] = _fcFtsAwarded;
        }
        finalLog['points'] = 0;
      case PrimaryAction.turnover:
        finalLog['actionType'] = 'TURNOVER';
        details['turnoverType'] = _toType;
        if (_toStolenByPlayer != null) {
          details['stolenByPlayer'] = {
            'playerId': _toStolenByPlayer!.id,
            'playerName': _toStolenByPlayer!.name,
            'jerseyNumber': _toStolenByPlayer!.jerseyNumber,
          };
        }
        finalLog['points'] = 0;
      case PrimaryAction.rebound:
        finalLog['actionType'] = 'REBOUND';
        details['reboundType'] = _rbType;
        finalLog['points'] = 0;
      case PrimaryAction.substitution:
        finalLog['actionType'] =
            _subDirection == 'IN' ? 'SUBSTITUTION_IN' : 'SUBSTITUTION_OUT';
        if (_subDirection == 'IN') {
          details['playerEntering'] =
              Map<String, dynamic>.from(finalLog['player'] as Map);
          if (_subOtherPlayer != null) {
            details['playerLeaving'] = {
              'playerId': _subOtherPlayer!.id,
              'playerName': _subOtherPlayer!.name,
              'jerseyNumber': _subOtherPlayer!.jerseyNumber,
            };
          }
        } else {
          details['playerLeaving'] =
              Map<String, dynamic>.from(finalLog['player'] as Map);
          if (_subOtherPlayer != null) {
            details['playerEntering'] = {
              'playerId': _subOtherPlayer!.id,
              'playerName': _subOtherPlayer!.name,
              'jerseyNumber': _subOtherPlayer!.jerseyNumber,
            };
          }
        }
        finalLog['points'] = 0;
      case PrimaryAction.timeout:
        finalLog['actionType'] = 'TIMEOUT_CALLED';
        details['timeoutType'] = 'TEAM';
        finalLog['points'] = 0;
      default:
        Navigator.of(context).pop();
        return;
    }

    finalLog['details'] = details;

    debugPrint('Final Log Data to Confirm: $finalLog');
    widget.onLogConfirm(finalLog);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    bool canConfirm = _selectedPrimaryAction != null;
    switch (_selectedPrimaryAction) {
      case PrimaryAction.shotAttempt:
        canConfirm =
            _saDetailType != null && _saOutcome != null && _saPointType != null;
      case PrimaryAction.foulCommitted:
        canConfirm = _fcType != null;
        if (_fcIsShootingFoul &&
            _fcFtsAwarded == null &&
            (_fcType == 'Personal' ||
                _fcType == 'Flagrant 1' ||
                _fcType == 'Flagrant 2')) {
          canConfirm = false;
        }
      case PrimaryAction.rebound:
        canConfirm = _rbType != null;
      case PrimaryAction.freeThrow:
        canConfirm = _ftIsMade != null;
      case PrimaryAction.turnover:
        canConfirm = _toType != null;
      case PrimaryAction.substitution:
        canConfirm = _subDirection != null && _subOtherPlayer != null;
      case PrimaryAction.timeout:
        canConfirm = true;
      case null:
        canConfirm = false;
    }

    return AlertDialog(
      title: Text(
        'Log Event for ${widget.playerInFocus.name} (#${widget.playerInFocus.jerseyNumber})',
      ),
      scrollable: true,
      content: SizedBox(
        width: MediaQuery.of(context).size.width < 500
            ? MediaQuery.of(context).size.width * 0.9
            : 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Quarter: ${widget.gameQuarter} | Clock: ${widget.gameClock}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 20),
            if (_selectedPrimaryAction == null)
              _buildPrimaryActionButtons()
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedPrimaryAction
                          .toString()
                          .split('.')
                          .last
                          .replaceAllMapped(
                            RegExp(r'[A-Z]'),
                            (match) => ' ${match.group(0)}',
                          )
                          .trim()
                          .capitalizeFirstLetter(),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    label: const Text(
                      'Change',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onPressed: () => setState(() {
                      _selectedPrimaryAction = null;
                      _resetSelectionsAndLogData();
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailsSection(),
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
          ),
          onPressed: canConfirm ? _confirmLogEntry : null,
          child:
              const Text('Confirm Log', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Helper extension for capitalizing first letter
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
