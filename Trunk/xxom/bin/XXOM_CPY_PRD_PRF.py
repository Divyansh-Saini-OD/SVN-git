import sys, os, re, datetime, time, shutil, string

def prevday():
	now=datetime.date.today()
	dif1=datetime.timedelta(days=1)
	day=now-dif1
	StrDay=day.strftime("%d%b%Y").upper()
	# StrDay=StrDay[8:10]
	return StrDay
	
def currday():
	now=datetime.date.today()
	StrDay=now.strftime("%d%b%Y").upper()
	return StrDay

print 'Previous Day = ' + prevday()
print 'Current Day  = ' + currday()

InBoundDir = '/app/ebs/ctgsiprdgb/xxom/archive/inbound/'
OutBoundDir = '/app/ebs/ctgsiprfgb/xxom/ftp/in/'
# InBoundDir = '/python/'
# OutBoundDir = '/python/'

# Blank out encryption label and value, a bogus value will be created in Oracle via HVOP using 
# the original 1st six last 4 so AJB can match transactions at recon time.
CardLabel = '                         '
EncryptCC = ['                                                ']
i=0

#############################################################################
#            Not in use for now
# Test card information:
# CardLabel = 'ORC20070713A             '
# CardCode = ['26']
# FirstSix = ['341111']
# Last4 = ['2000']
# EncryptCC = ['E39A8228D7652B05B0E40BCC0A33B685F0EEB2B1C528FB5D']
#
# CACardCode = ['25']
# CA1stSix = ['544298']
# CALast4 = ['6024']
# CAEncryptCC = ['D07D7CEA5EEE2C7D22F186E30ED28F19EB24312D9FBB4BD9']
# y=0
#############################################################################

# First do Wave 1 and 2
regex='^SAS[CU][SA]EOT[12][.]TXT[.]' + str(prevday()) + ':[12][0-9]:[0-9]{2}:[0-9]{2}'
# regex='^SAS[CU][SA]EOT[2][.]TXT[.]' + str(prevday()) + '[A-Z]{3}[0-9]{4}:[12][0-9]:[0-9]{2}:[0-9]{2}'
# regex='^SAS[CU][SA]EOT[12][.]TXT'

fname = []

iFilter = re.compile(regex)

flist = os.listdir(InBoundDir)

for f in flist:
	if iFilter.match(f):
		fname.append(f)

for h in fname:
	s = h[0:13]
	
	for line in open(InBoundDir + h):
		try:
      			filename = line.strip()
      			print 'Copying ' + filename + '.done' + ' to ' + filename
      			# shutil.copy(InBoundDir + filename + '.done', OutBoundDir + filename)

			# Add test credit cards
			country = h[3:5]
			outfile=open(OutBoundDir + filename, 'w')
			# for tran in open(OutBoundDir + filename):
			for tran in open(InBoundDir + filename + '.done'):
				if tran[20:22] == '40' and (tran[35:37] == '14' or tran[35:37] == '16' or tran[35:37] == '17' or tran[35:37] == '18' or tran[35:37] == '20' or tran[35:37] == '22' or tran[35:37] == '24' or tran[35:37] == '25' or tran[35:37] == '26' or tran[35:37] == '27' or tran[35:37] == '29'):
					tran = tran[0:173] + CardLabel + EncryptCC[i] + tran[246:331] + '\n'
					# if country == 'US':
					# 	tran = tran[0:35] + CardCode[i] + tran[37:48] + FirstSix[i] + Last4[i] + tran[58:173] + CardLabel + EncryptCC[i] + tran[246:331] + '\n'
				        # else:
					# 	tran = tran[0:35] + CACardCode[y] + tran[37:48] + CA1stSix[y] + CALast4[y] + tran[58:173] + CardLabel + CAEncryptCC[y] + tran[246:331] + '\n'
				outfile.write(tran)
			outfile.close

		except IOError:
			print 'Ooops, no file to copy'
		
				
			
	
	# Copy EOT file
	print 'Copying ' + h + ' to ' + s
	shutil.copy(InBoundDir + h, OutBoundDir + s)
	os.chmod(OutBoundDir + s,0777)
		

# Now do Wave 3 and 5
print 'Wave 3 and 5'
regex='^SAS[CU][SA]EOT[235][.]TXT[.]' + str(currday()) + ':[012][0-9]:[0-9]{2}:[0-9]{2}'

fname = []

iFilter = re.compile(regex)

flist = os.listdir(InBoundDir)
for f in flist:
	if iFilter.match(f):
		fname.append(f)

for h in fname:
	s = h[0:13]
	
	for line in open(InBoundDir + h):
		try:
      			filename = line.strip()
      			print 'Copying ' + filename + '.done' + ' to ' + filename
      			# shutil.copy(InBoundDir + filename + '.done', OutBoundDir + filename)

			# Add test credit cards
			country = h[3:5]
			outfile=open(OutBoundDir + filename, 'w')
			# for tran in open(OutBoundDir + filename):
			for tran in open(InBoundDir + filename + '.done'):
				if tran[20:22] == '40' and (tran[35:37] == '14' or tran[35:37] == '16' or tran[35:37] == '17' or tran[35:37] == '18' or tran[35:37] == '20' or tran[35:37] == '22' or tran[35:37] == '24' or tran[35:37] == '25' or tran[35:37] == '26' or tran[35:37] == '27' or tran[35:37] == '29'):
					tran = tran[0:173] + CardLabel + EncryptCC[i] + tran[246:331] + '\n'
					# if country == 'US':
					# 	tran = tran[0:35] + CardCode[i] + tran[37:48] + FirstSix[i] + Last4[i] + tran[58:173] + CardLabel + EncryptCC[i] + tran[246:331] + '\n'
				        # else:
					# 	tran = tran[0:35] + CACardCode[y] + tran[37:48] + CA1stSix[y] + CALast4[y] + tran[58:173] + CardLabel + CAEncryptCC[y] + tran[246:331] + '\n'
				outfile.write(tran)
			outfile.close
		except IOError:
			print 'Ooops, no file to copy'
		
				
			
	
	# Copy EOT file
	print 'Copying ' + h + ' to ' + s
	shutil.copy(InBoundDir + h, OutBoundDir + s)
	os.chmod(OutBoundDir + s,0777)

print 
print 'Copy complete'