#!/usr/bin/perl

# NOTE:
# ConvertWord() provides a single solution which may not always be correct
# it finds the fastest probable 'solution'... But the backend may not recognize it as correct
# ie: duplicate letters on the board may cause issues... 
# MAY need to check if next letter is congruent to current letter. if not keep looking for next duplicate... 
#  => if no next duplicate then the original first letter is wrong starting place

use JSON;

my $userID = "xx";
my $cookie = "xx";

print "\n";

# make new game on execute, if you comment this out, the script will just play your current open games
CreateNewGame();

# delete finished games
system(`curl -s -H "Host: api.mezcladitos.com" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.2.2|en-US|en-US|US|1" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: AngryMix/2.2.2 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Accept-Language: en-us" --data-binary "" -X DELETE --compressed http://api.mezcladitos.com/api/users/$userID/games`);

# play all opens games
PlayOpenGames();

# set to 1 if you only want to create a game and NOT play any games
# set to 0 if you want to also play any open games
$ONLY_MAKE_GAMES = 0;

sub CreateNewGame {
	my $response = `curl -s -H "Host: api.mezcladitos.com" -H "Content-Type: application/json; charset=utf-8" -H "Accept-Language: en-us" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: AngryMix/2.2.2 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.2.2|en-US|en-US|US|1" --data-binary '{"smart_ready":true,"language":"EN"}' --compressed http://api.mezcladitos.com/api/users/$userID/games`;
	my $newGameID = decode_json($response)->{id};
	
	if (!defined $newGameID) {
		print "Could not make another new game yet!\n(Play any open games?)\n";
	}
	else {
		my $newGameSession = `curl -s -H "Host: api.mezcladitos.com" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.2.2|en-US|en-US|US|1" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: AngryMix/2.2.2 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Accept-Language: en-us" --data-binary "" -X GET --compressed http://api.mezcladitos.com/api/users/$userID/games/$newGameID?`;
	}
}

if ($ONLY_MAKE_GAMES) {
	print "Only making games.\n";
	exit;
}

our $totalPoints = 0;

sub PlayOpenGames {
	my $dashboard = `curl -s -H "Host: api.mezcladitos.com" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.2.2|en-US|en-US|US|1" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: AngryMix/2.2.2 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Accept-Language: en-us" --data-binary "" -X GET --compressed http://api.mezcladitos.com/api/users/$userID/games?app_config_version=12548398&smart_ready=true`;
	$dashboard = decode_json($dashboard);
	my @gameList = @{$dashboard->{list}};
	print "\nYou have " . $dashboard->{total} . " open games\n\n";

	foreach my $game (@gameList) {
		if ((($game->{game_status} eq "ACTIVE") || ($game->{game_status} eq "PENDING_FIRST_MOVE"))&& ($game->{my_turn})) {
			my $opponentName = "Random opponent";
			$opponentName = $game->{opponent}{username} if ($game->{opponent}{username});
			print "Need to play vs " . $opponentName . "\n";
			my $gameID = $game->{id};
			my $getGameState = `curl -s -H "Host: api.mezcladitos.com" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.2.2|en-US|en-US|US|1" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: AngryMix/2.2.2 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Accept-Language: en-us" --data-binary "" -X GET --compressed http://api.mezcladitos.com/api/users/$userID/games/$gameID?`;
			#print $getGameState;

			#round = 4-#of_stars(*)
			my $roundWinners = $game->{round_winners};
			$roundWinners =~ s/[^*]//g;
			my $round = (4 - length $roundWinners);

			$totalPoints = 0;

			print "ROUND TO GO: $round \n";
			my $gameStateData = `curl -s -H "Host: api.mezcladitos.com" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.2.2|en-US|en-US|US|1" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: AngryMix/2.2.2 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Accept-Language: en-us" --data-binary "" -X GET --compressed http://api.mezcladitos.com/api/users/$userID/games/$gameID/rounds/$round`;
			DoRounds($gameStateData, $round, $gameID);
			sleep(1);
		}
	}
}

sub DoRounds {
	my ($gamestate, $round, $gameID) = @_;
	my $newGame = decode_json($gamestate);

	my $boardData = $newGame->{board};
	my @boardDataArray = split(m/,/, $boardData);

	# bonus to distribution from board index...
	my $bonusData = $newGame->{bonus};
	my @bonusDataArray = split(m/,/, $bonusData);

	# sub PrintTable {
	# 	print "Table View:\n\n";

	# 	my $counter = 0;
	# 	foreach my $letter (@boardDataArray) {
	# 		print substr($letter, 0, 1);
			
	# 		$counter++;
	# 		if (($counter % 4) eq 0) {
	# 			print "\n";
	# 		}
	# 		else {
	# 			print " ";
	# 		}
	# 	}
	# }

	my $boardWords = $newGame->{board_words};
	my @boardWordsArray = split(m/,/, $boardWords);

	my $releaseAnswer = "";

	$counter = 0;
	foreach my $answer (@boardWordsArray) {

		#print $answer;
		$releaseAnswer .= ConvertWord($answer, 1, $boardData, $bonusData);

		$counter++;
		if ($totalPoints > 320) {
			print "\n";
			last;
		}
	}
	$releaseAnswer =~ s/,$//g;
	#print $releaseAnswer."\n";
	print "Submitting answer worth: " . $totalPoints . "\n========\n";

	my $gameOver = `curl -s -H "Host: api.mezcladitos.com" -H "Content-Type: application/json; charset=utf-8" -H "Accept-Language: en-us" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: AngryMix/2.2.2 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.2.2|en-US|en-US|US|1" --data-binary '{"words":"$releaseAnswer","turn_type":"PLAY","points":"$totalPoints","coins":"0"}' --compressed http://api.mezcladitos.com/api/users/$userID/games/$gameID/rounds/$round`;
}

# 0, 1, 2, 3
# 4, 5, 6, 7
# 8, 9, 10,11
# 12,13,14,15

# not yet implemented.
my @allowedIndexes = ('1,4,5', '0,4,5,6,2', '1,5,6,7,3', '2,6,7', '0,1,5,9,8', '0,1,2,4,6,8,9,10', '1,2,3,5,7,9,10,11', '2,3,6,10,11', '4,5,9,12,13', '4,5,6,8,10,12,13,14', '5,6,7,9,11,13,14,15', '6,7,10,14,15', '8,9,13', '8,9,10,12,14', '9,10,11,13,15', '10,11,14');

sub ConvertWord {
	my ($word, $skip, $boardData, $bonusData) = @_;

	my @definitions = ('\u0001','\u0002','\u0003','\u0004','\u0005','\u0006','\u0007','\b','\t','\n','\u000b','\f','\r','\u000e','\u000f','\u0010');
	my @distributions = ('a:1','b:3','c:3','d:2','e:1','f:4','g:2','h:4','i:1','j:8','k:5','l:1','m:3','n:1','o:1','p:3','q:10','r:1','s:1','t:1','u:1','v:4','w:4','x:8','y:4','z:10');

	my @boardDataArray = split(m/,/, $boardData);
	my @bonusDataArray = split(m/,/, $bonusData);

	#my $firstPlace = -1;
	my @wordToLetters = split("", $word);
	my $stringBuilder = "";
	my $worth = 0;
	my $wordMultiplier = 1;

	# for each letter in the word
	foreach my $letter (@wordToLetters) {
		my $index = 0;

		# for each board layout (16)
		foreach my $boardLetter (@boardDataArray) {
			if (substr($boardLetter, 0, 1) eq $letter) {

				# for each distribution (normal not bonus)
				foreach my $value (@distributions) {
					if ($letter eq substr($value, 0, 1)) {
						my $currentWorth = substr($value, 2, 2);
						
						#apply bonus
						# for each additional bonus distribution
						foreach my $bonusPossible (@bonusDataArray) {
							$wordMultiplier = 1;
							my $bonusIndex = substr($bonusPossible, 0, 2);
							$bonusIndex =~ s/-//g;

							if ($index eq $bonusIndex) {
								my $bonusType = substr($bonusPossible, 2, 3);
								$bonusType =~ s/-//g;

								if ($bonusType eq "DL") {
									$currentWorth *= 2;
								}
								elsif ($bonusType eq "DW") {
									$wordMultiplier = 2;
								}
								if ($bonusType eq "TL") {
									$currentWorth *= 3;
								}
								elsif ($bonusType eq "TW") {
									$wordMultiplier = 3;
								}
							}
						}
						
						$worth += $currentWorth;
					}
				}

				$stringBuilder .= $definitions[$index];
				#print ">>".$definitions[0]."<<";
				last;
			}

			$index++;
		}
	}

	$worth *= $wordMultiplier;
	$totalPoints += $worth;
	return $stringBuilder.":".$worth.",";
}






