import random, math, os
populationInfo = []
babies = []
f = open('scores.txt', 'r')
for line in f:
    populationInfo.append(line.split())
f.close()

#for item in populationInfo:
#    for item2 in item:
#        item2 = float(item2)

#print(len(populationInfo))
#print(int(math.ceil(float(len(populationInfo))/10*3)))
for number in range(int(math.ceil(float(len(populationInfo))/10*3))):
    randomInts = set()
    while len(randomInts) < int(math.ceil(float(len(populationInfo))/10)):
        randomInts.add(random.randint(0,len(populationInfo)-1))

    maxScore = 0
    secondScore = 0
    maxScorePosition = 0
    secondScorePosition = 0

    for index in randomInts:
        if int(populationInfo[index][5]) > maxScore:
            secondScore = maxScore
            secondScorePosition = maxScorePosition
            maxScore = int(populationInfo[index][5])
            maxScorePosition = index
        elif int(populationInfo[index][5]) > secondScore:
            secondScorePosition = index
            secondScore = int(populationInfo[index][5])

    totalScore = maxScore + secondScore
    maxScore = float(maxScore) / totalScore
    secondScore = float(secondScore) / totalScore
    babies.append([])
    for index in range(5):
        babies[number].append(float(populationInfo[maxScorePosition][index])*maxScore + float(populationInfo[secondScorePosition][index])*secondScore)
    babies[number].append(0)
    mutateChance = random.random()
    if mutateChance <= .05:
        plusMinus = random.randint(0,1)
        mutateIndex = random.randint(0,3)
        if plusMinus == 1:
            babies[number][mutateIndex] += .2
        else:
            babies[number][mutateIndex] -= .2

populationInfo = sorted(populationInfo, key=lambda x:int(x[5]), reverse=True)


f = open('population.txt','w')
for baby in babies:
    f.write(str(baby[0]) + ' ' + str(baby[1]) + ' ' + str(baby[2]) + ' ' + str(baby[3]) + ' ' + str(baby[4]) + ' ' + str(baby[5]) + '\n')

for i in range(len(populationInfo)-int(math.ceil(float(len(populationInfo)/10*3)))):
    f.write(str(populationInfo[i][0]) + ' ' + str(populationInfo[i][1]) + ' ' + str(populationInfo[i][2]) + ' ' + str(populationInfo[i][3]) + ' ' + str(populationInfo[i][4]) + ' ' + str(populationInfo[i][5]) + '\n')

os.remove('scores.txt')
