
TERRASCAN_SERVER=192.168.1.55
TERRASCAN_PORT=9010
IGNORE_LOW_SEVERITY=false
IAC=terraform
IAC_VERSION=v14
CLOUD_PROVIDER=aws

SCAN_URL="${TERRASCAN_SERVER}:$TERRASCAN_PORT/v1/${IAC}/${IAC_VERSION}/${CLOUD_PROVIDER}/local/file/scan"
ALLSCANS=$(mktemp terrascan_outputs.XXXX)
CURRENTSCAN=$(mktemp terrascan_output.XXXX)

for f in `find . -name *.tf`; do
    curl --silent -F "file=@$f" --output $CURRENTSCAN $SCAN_URL
    cat $CURRENTSCAN >> $ALLSCANS
    rm $CURRENTSCAN
done

SCAN_RESULTS=0
# "severity:" only shows up if a rule was violated, so decent way to search multiple files for violations
SEVERITIES=`grep \"severity:\" $ALLSCANS `
if [[ $IGNORE_LOW_SEVERITY == "true" ]]; then
    SEVERITIES=`echo $SEVERITIES | grep -vi low`
fi
if [ -n $SEVERITIES ]; then
    SCAN_RESULTS=1
    echo
    echo '- Terrascan identified IAC policy violations:'
    echo
    echo 'Scan Results:'
    cat $ALLSCANS
    echo
    echo '```'
    echo '</details>'
    echo '<p><strong>Further atlantis details below:</strong></p>'
    echo '<details>'
    echo
    echo '```diff'
    echo
fi
rm $ALLSCANS
exit $SCAN_RESULTS
