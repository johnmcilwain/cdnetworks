# ********************************************************************************************************************************* #
# Name: api_example_perl.pl                                                                                                         #
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
use Data::Dumper;
use JSON;	
use LWP::UserAgent;
use Term::ReadPassword;
use GD::Graph::bars;
use GD::Graph::Data;

use strict; use warnings;

my $USER        = `cat ./_user.db`;                                     # Create _user.db with your username inside
my $PASS        = `cat ./_pass.db`;                                     # Create _pass.db with your password inside
my $SVCGRP      = 'YourServiceGRP';                                     # Change to your desired SERVICE GROUP
my $APIKEY      = 'YourDomainPAD';                                      # Change to your desired APIKEY (website)
my $TRAFFICDATA = '&fromDate=20170201&toDate=20170201&timeInterval=1';  # Change to your desired graph date/time
my $GRAPHFILE   = 'api_example_perl_graph.png';                         # Change to your desired graph filename
my $APIENDPOINT = 'https://openapi.cdnetworks.com/api/rest/';           # Don't change
my $APIFORMAT   = '&output=json';                                       # Don't change
my $FONTLOC     = '/System/Library/Fonts/';                             # Change if not on a Mac
my $FONT        = 'Palatino.ttc';                                       # Change if needed
my $DEBUG       = 1;                                                    # Set to 0 to hide text output
my $API_SUCCESS = 0;                                                    # Don't change

# Setup user-agent
my $ua = LWP::UserAgent->new();
$ua->timeout(10);
my $retval = 0;

# Command: LOGIN : send login, receive list of service groups (logial grouping, like a directory)
print "Control Groups\n"  if $DEBUG;
my $url  = $APIENDPOINT . 'login?user=' . $USER . '&pass=' . $PASS . $APIFORMAT;
print "\tURL: $APIENDPOINT" . "login?user=xxx&pass=xxx\n"  if $DEBUG;

my $resp = $ua->get($url);
my $json = decode_json($resp->decoded_content());

$retval = $json->{'loginResponse'}{'resultCode'};
die "API Failed, code: $retval"  if $retval != $API_SUCCESS;
print "\tloginResponse: resultCode = $retval\n"  if $DEBUG;
my $ra_svcgrps = $json->{'loginResponse'}{'session'};

# Loop through and find $SVCGRP specific Service Group
my $session = '';
foreach my $rh_svcgrp (@{$ra_svcgrps}) {
	if ($rh_svcgrp->{'svcGroupName'} eq $SVCGRP) {
		print "\tFound: " . $rh_svcgrp->{'svcGroupName'} . "\n"  if $DEBUG;
		$session = $rh_svcgrp->{'sessionToken'};
		print "\t\tSelected: " . $session . "\n"  if $DEBUG;
		last;
	}
}


# Command: APIKEYLIST : get list of APIs for Service Groups
print "\nAPI Key List\n"  if $DEBUG;
$url  = $APIENDPOINT . 'getApiKeyList?sessionToken=' . $session . $APIFORMAT;
print "\tURL: $url\n"  if $DEBUG;

$resp = $ua->get($url);
$json = decode_json($resp->decoded_content());

$retval = $json->{'apiKeyInfo'}{'returnCode'};
die "API Failed, code: $retval"  if $retval != $API_SUCCESS;
print "\tapiKeyInfo: returnCode = $retval\n"  if $DEBUG;
my $ra_apikeys = $json->{'apiKeyInfo'}{'apiKeyInfoItem'};

# Loop through and find $APIKEY specific API Key
my $apikey = '';
foreach my $rh_apikeys (@{$ra_apikeys}) {
	if ($rh_apikeys->{'serviceName'} eq $APIKEY) {
		print "\tFound: " . $rh_apikeys->{'serviceName'} . "\n"  if $DEBUG;
		$apikey = $rh_apikeys->{'apiKey'};
		print "\t\tSelected: " . $apikey . "\n"  if $DEBUG;
		last;
	}
}


# Command: EDGE TRAFFIC : get edge traffic raw data
print "\nEdge/Traffic\n"  if $DEBUG;
$url  = $APIENDPOINT . 'traffic/edge?sessionToken=' . $session . '&apiKey=' . $apikey . $TRAFFICDATA . $APIFORMAT;
print "\tURL: $url\n"  if $DEBUG;

$resp = $ua->get($url);
$json = decode_json($resp->decoded_content());

$retval = $json->{'trafficResponse'}{'returnCode'};
die "API Failed, code: $retval"  if $retval != $API_SUCCESS;
print "\ttrafficResponse: returnCode = $retval\n"  if $DEBUG;
my $ra_trafficitems = $json->{'trafficResponse'}{'trafficItem'};

my $traffic = '';
my @graph_time;
my @graph_trans;
foreach my $rh_trafficitems (@{$ra_trafficitems}) {
	print "\tFound: " . $rh_trafficitems->{'dateTime'} . "\n"  if $DEBUG;
	print "\tFound: " . $rh_trafficitems->{'dataTransferred'} . "\n"  if $DEBUG;
    push(@graph_time, $rh_trafficitems->{'dateTime'});
    push(@graph_trans, $rh_trafficitems->{'dataTransferred'});
}


# Generate and save graph (create nice looking labels first)
my @graph_time_pretty = @graph_time;
foreach my $text (@graph_time_pretty) {
    $text =~ s/(\d{4})(\d{2})(\d{2})(\d{4})/$1-$2-$3-$4/;
}

my $data = GD::Graph::Data->new([\@graph_time_pretty, \@graph_trans]) or die GD::Graph::Data->error();
my $graph = GD::Graph::bars->new(1024, 768);

GD::Text->font_path($FONTLOC);
$graph->set_title_font($FONT, 28);
$graph->set_legend_font($FONT, 18);
$graph->set_x_label_font($FONT, 18);
$graph->set_x_axis_font($FONT, 12);
$graph->set_y_label_font($FONT, 18);
$graph->set_y_axis_font($FONT, 12);
 
$graph->set( 
    x_label             => 'Date/Time',
    x_labels_vertical   => 1,
    y_label             => 'Data Transferred (bytes)',
    title               => 'Edge Traffic', 
    bar_spacing         => 10,
    shadow_depth        => 4,
    transparent         => 0,
) or die $graph->error();

$graph->set_legend($APIKEY) or die $graph->error();
$graph->plot($data) or die $graph->error();
 
open(my $out, '>', $GRAPHFILE) or die "Cannot open $GRAPHFILE for write: $!";
binmode $out;
print $out $graph->gd->png();
close $out;
 

# Command: LOGOUT : send token to invalidate
print "\nLogout\n"  if $DEBUG;
$url  = $APIENDPOINT . 'logout?sessionToken=' . $session . '&output=json';
print "\tURL: $url\n"  if $DEBUG;
$resp = $ua->get($url);
$json = decode_json($resp->decoded_content());
$retval = $json->{'logoutResponse'}{'resultCode'};
# Ignoring $retval
print "\tlogoutResponse: resultCode = $retval\n"  if $DEBUG;





