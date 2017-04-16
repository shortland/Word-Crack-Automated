# Word-Crack-Automated
Full automation for the game Word Crack

You can get your cookie and user ID with some MITM proxy...

Upon execution, script will make a new game (if it can) and also play any of the open pre-existing games...

It's limited to only solve up to 320points worth of words at once... Anything higher could be "suspicious"...

ALSO: If you use this - it's pretty blatant since the words it solves don't always connect [ others can see that D: ]
 - Because their server apparently doesn't check for that - I'm gonna be lazy and call it a job done :)


(You can execute it as often as you want. I put mine on a cron-job to run every 2 minutes)
 - Theres no limit (from what I can see) of how many open games you can have.
 - The only limiting factor is you can only have 1 open game in which it's the first round and your turn. Play the first round and a new game can be created. (an opponent must also be found)
