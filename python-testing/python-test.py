is_game_over = False
print(is_game_over)  # Output: False
is_game_over = True
print(is_game_over)  # Output: True
is_game_over = 5 > 6
print(is_game_over)  # Output: False


num_lives = 5
print(num_lives)  # Output: 5
percent_health = 0.5
print(percent_health)  # Output: 0.5

player_name = "LaMont"
print(player_name)  # Output: LaMont
player_name = 'Neo S'
print(player_name)  # Output: Neo S

print(type(is_game_over))
print(type(num_lives))
print(type(percent_health))

num_lives = "5"
print(type(num_lives))


you_are_a_winner = 25 > 11
print(type(you_are_a_winner)) # Output: Boolean type

lives_left = 10
print(type(lives_left)) # Output: Integer type

health_percentage = 0.75
print(type(health_percentage)) # Output: Float type

player_1_name = "Alice"
print(type(player_1_name)) # Output: String type

player_1_name = health_percentage
print(type(player_1_name)) # Output: Float type

##############################################
# Write more code below this line #
##############################################

num_lives = 7
print(str(num_lives) + " lives remaining") # Output: 7 lives remaining

num_lives = 8
# num_lives is an integer, so we convert it to a string using str()
str_num_lives = str(num_lives)
print("Be careful, you only have " + str_num_lives + " lives left!") # Output: Be careful, you only have x lives left!


print(bool(0))       # Output: False
print(bool(2))      # Output: True
print(bool(-3))     # Output: True
print(bool("adhfkjasdhfkja"))      # Output: True
print(bool(""))     # Output: False
print(bool([]))     # Output: False
print(bool(0.0000000000000000000000000000000000000000000000000000000001))  # Output: True

# print(int("asdhfasdhf")) # This will raise a ValueError

print(int(0.9999))  # Output: 0
print(int(1.9999))  # Output: 1
print(int(True))
print(int(False))


print(float("1"))
print(float(5))
print(float(False))
print(float(True))



##############################################
# Write more code below this line #
##############################################

# Operators

health = 50
new_health = health + 20
print(health) # Output: 50
health = health + 20
print(health) # Output: 70

xPos = 5
print(xPos % 2) # Output: 1
print(xPos // 2) # Output: 2
print(xPos)

first_name = "LaMont"
last_name = "Session"
print(first_name + " " + last_name) # Output: LaMont Session



