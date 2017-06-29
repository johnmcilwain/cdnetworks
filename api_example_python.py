# ********************************************************************************************************************************* #
# Name: api_example_python.py                                                                                                       #
# Desc: full api example                                                                                                            #
# Auth: john mcilwain (jmac) - (jmac@cdnetworks.com)                                                                                #
# Ver : .90                                                                                                                         #
# License:                                                                                                                          #
#   This sample code is provided on an "AS IS" basis.  THERE ARE NO                                                                 #
#   WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED                                                        #
#   WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR                                                    #
#   PURPOSE, REGARDING THE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN                                                            #
#   COMBINATION WITH YOUR PRODUCTS.                                                                                                 #
# ********************************************************************************************************************************* #
import os
import sys
import json
import pygal
import re
import urllib.request


USER          = os.popen('cat ./_user.db').read()                       # Create _user.db with your username inside
PASS          = os.popen('cat ./_pass.db').read()                       # Create _pass.db with your password inside
SVCGRP        = 'YourServiceGRP'                                        # Change to your desired SERVICE GROUP
APIKEY        = 'YourDomainPAD'                                         # Change to your desired APIKEY (website)
TRAFFICDATA   = '&fromDate=20170201&toDate=20170201&timeInterval=1'     # Change to your desired graph date/time
GRAPHFILE     = 'api_example_python_graph'                              # Change to your desired graph filename
APIENDPOINT   = 'https://openapi.cdnetworks.com/api/rest/'              # Don't change
APIFORMAT     = '&output=json'                                          # Don't change
API_SUCCESS   = 0                                                       # Don't change


# Command: LOGIN : send login, receive list of service groups (logial grouping, like a directory)
print('Control Groups')
url = APIENDPOINT + 'login?user=' + USER + '&pass=' + PASS + APIFORMAT;
print('\tURL: ' + APIENDPOINT + 'login?user=xxx&pass=xxx')

parsed = json.load(urllib.request.urlopen(url))
retval = parsed['loginResponse']['resultCode']

print('\tloginResponse: resultCode = %s' % retval)

# Loop through and find SVCGRP specific Service Group
sessToken = '';
sessions = parsed['loginResponse']['session']
for session in sessions:
    if session['svcGroupName'] == SVCGRP:
        print('\tFound: %s' % session['svcGroupName'])
        print('\t\tSelected: %s' % session['sessionToken'])
        sessToken = session['sessionToken']
        break


# Command: APIKEYLIST : get list of APIs for service groups
print('\nAPI Key List')
url = APIENDPOINT + 'getApiKeyList?sessionToken=' + sessToken + APIFORMAT;
print('\tURL: %s' % url)

parsed = json.load(urllib.request.urlopen(url))
retval = parsed['apiKeyInfo']['returnCode']
if retval != API_SUCCESS:  
    print('API Failed, code: %s' % retval)
    sys.exit()
print('\tapiKeyInfo: returnCode = %s' % retval)

# Loop through and find the APIKEY specific API Key
apiKey = ''
apikeys = parsed['apiKeyInfo']['apiKeyInfoItem']
for apikey in apikeys:
    if apikey['serviceName'] == APIKEY:
        print('\tFound: %s' % apikey['serviceName'])
        print('\t\tSelected: %s' % apikey['apiKey'])
        apiKey = apikey['apiKey']
        break


# Command: EDGE TRAFFIC : get edge traffic raw data
print('\nTraffic/Edge')
url  = APIENDPOINT + 'traffic/edge?sessionToken=' + sessToken + '&apiKey=' + apiKey + TRAFFICDATA + APIFORMAT;
print('\tURL: %s' % url)

parsed = json.load(urllib.request.urlopen(url))
retval = parsed['trafficResponse']['returnCode']
if retval != API_SUCCESS:  
    print('API Failed, code: %s' % retval)
    sys.exit()
print('\tapiKeyInfo: returnCode = %s' % retval)

# Show all Traffic details
chartListTimes = []
chartListTrans = []
trafficItems = parsed['trafficResponse']['trafficItem']
for item in trafficItems:
    print('\tFound: %s' % item['dateTime'])
    print('\tFound: %s' % item['dataTransferred'])
    chartListTimes.append(item['dateTime'])
    chartListTrans.append(item['dataTransferred'])

# Generate and save graph (create nice looking labels first)
chartListTimesPretty = []
for date in chartListTimes: #format with hyphens: 201702011700
    chartListTimesPretty.append( "%s-%s-%s-%s" % (str(date)[:4], str(date)[4:6], str(date)[6:8], str(date)[8:]))

bar_chart = pygal.Bar(width=1024, height=768)                                           
bar_chart.title = "Edge Traffic"
bar_chart.x_title = "Date/Time"
bar_chart.y_title = "Data Transferred (bytes)"
bar_chart.x_label_rotation = 270
bar_chart.legend_at_bottom = 1

bar_chart.x_labels = chartListTimesPretty
bar_chart.add(APIKEY, chartListTrans) 

bar_chart.render_to_file(GRAPHFILE + '.svg')       
bar_chart.render_to_png(GRAPHFILE + '.png')       


# Command: LOGOUT : send token to invalidate
print('\nLogout')
url = APIENDPOINT + 'logout?sessionToken=' + sessToken + APIFORMAT
print('\tURL: %s' % url)
parsed = json.load(urllib.request.urlopen(url))
retval = parsed['logoutResponse']['resultCode']
# Ignoring retval
print('\tlogout: resultCode = %s' % retval)





