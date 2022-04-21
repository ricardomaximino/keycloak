#
#    This sample Windows PowerShell script will:
#        1.) Create a Certificate Authority
#        2.) Create a Server Certificate signed by the Certificate Authority
#        3.) Create a Client Certificate signed by the Certificate Authority
#        4.) Create a TrustStore containing the public Certificate Authority key
#
#    The first section defines variables
#    The second section does the work
#
#    All Key Stores are PKCS12
#
#    The Server Certificate includes a Subject Alternative Name
#        The command below uses the serverAlias as the serverDNS value, but may be changed to whatever you need
#
#    You just have Java 7 (or higher) installed and keytool in your path
#

# Root Organizational Information #
$ca_organizationalUnit="BrasaTech IT"
$ca_organization="BrasaTech Digital Solutions"
$ca_locality="Santa Pola"
$ca_state="Alicante"
$ca_country="ES"

# Server Organizational Information #
# Subject Alternative Name #
$serverDNS="brasatech.es"
$altserverDNS="dns:brasatech.es,dns:*.brasatech.es,dns:localhost"
$server_organizationalUnit="BrasaTech IT"
$server_organization="BrasaTech Digital Solutions"
$server_locality="Santa Pola"
$server_state="Alicante"
$server_country="ES"

# Client Organizational Information #
$client_organizationalUnit="BrasaTech IT"
$client_organization="BrasaTech Digital Solutions"
$client_locality="Santa Pola"
$client_state="Alicante"
$client_country="ES"

# Certificate Alias #
$authorityAlias="brasatech-root"
$serverAlias="brasatech-server"
$clientAlias="brasatech-client"

# Extensions #
$certAuthExtension="BasicConstraints:critical=ca:true,pathlen:10000"
$altNameExtension="san=$altserverDNS"

# Trust Store #
$trustCertName="truststore"

# Key size and effective period #
$keySize="4096"
$validity="365"
$storeType="PKCS12"

# Key and Store Password #
$certPassword="changeit"

# ------------------------------------------------------------------------------------------ #
# ------------------  Use caution if you change anything below this line  ------------------ #
# ------------------------------------------------------------------------------------------ #

$authorityDN="CN=$authorityAlias,OU=$ca_organizationalUnit,O=$ca_organization,L=$ca_locality,ST=$ca_state,C=$ca_country"
$serverDN="CN=$serverDNS,OU=$server_organizationalUnit,O=$server_organization,L=$server_locality,ST=$server_state,C=$server_country"
$clientDN="CN=$clientAlias,OU=$client_organizationalUnit,O=$client_organization,L=$client_locality,ST=$client_state,C=$client_country"

rm "$authorityAlias.*"
rm "$serverAlias.*"
rm "$clientAlias.*"
rm "$trustCertName.*"
rm "$truststore.*"

echo ""
echo "Generating the Root Authority Certificate..."
keytool -genkeypair -alias "$authorityAlias" -keyalg RSA -dname "$authorityDN" -ext "$certAuthExtension" `
    -validity "$validity" -keysize "$keySize" -storetype "$storeType" -keystore "$authorityAlias.p12" -keypass "$certPassword" `
    -storepass "$certPassword" -deststoretype pkcs12

echo "- Exporting Root Authority Certificate Public Key..."
keytool -exportcert -rfc -alias "$authorityAlias" -file "$authorityAlias.cer" -keypass "$certPassword" `
    -keystore "$authorityAlias.p12" -storepass "$certPassword"


echo ""
echo "Generating the Server Certificate..."
echo "- Creating Key Pair"
keytool -genkey -validity "$validity" -keysize "$keySize" -alias "$serverAlias" -keyalg RSA -dname "$serverDN" `
    -ext "$altNameExtension" -keystore "$serverAlias.p12" -keypass "$certPassword" -storetype "$storeType" -storepass "$certPassword" `
    -deststoretype pkcs12

echo "- Exporting Server Certificate Private Key..."
keytool -exportcert -alias "$serverAlias" -file "$serverAlias.key" -keypass "$certPassword" `
    -keystore "$serverAlias.p12" -storepass "$certPassword"    

echo "- Creating Certificate Signing Request"
keytool -certreq -alias "$serverAlias" -ext "$altNameExtension" -keystore "$serverAlias.p12" -file "$serverAlias.csr" `
    -keypass "$certPassword" -storepass "$certPassword"

echo "- Signing Certificate"
keytool -gencert -infile "$serverAlias.csr" -keystore "$authorityAlias.p12" -storepass "$certPassword" `
    -alias "$authorityAlias" -ext "$altNameExtension" -outfile "$serverAlias.pem"

echo "- Adding Certificate Authority Certificate to Keystore"
keytool -import -trustcacerts -alias "$authorityAlias" -file "$authorityAlias.cer" -keystore "$serverAlias.p12" `
    -storepass "$certPassword" -noprompt

echo "- Adding Certificate to Keystore"
keytool -import -keystore "$serverAlias.p12" -file "$serverAlias.pem" -alias "$serverAlias" -keypass "$certPassword" `
    -storepass "$certPassword" -noprompt
rm "$serverAlias.csr"
# rm "$serverAlias.pem"

echo ""
echo "Generating the Client Certificate..."
echo "- Creating Key Pair"
keytool -genkey -validity "$validity" -keysize "$keySize" -alias "$clientAlias" -keyalg RSA -dname "$clientDN" `
    -keystore "$clientAlias.p12" -keypass "$certPassword" -storetype "$storeType" -storepass "$certPassword" -deststoretype pkcs12

echo "- Creating Certificate Signing Request"
keytool -certreq -alias "$clientAlias" -keystore "$clientAlias.p12" -file "$clientAlias.csr" -keypass "$certPassword" `
    -storepass "$certPassword"

echo "- Signing Certificate"
keytool -gencert -infile "$clientAlias.csr" -keystore "$authorityAlias.p12" -storepass "$certPassword" `
    -alias "$authorityAlias" -outfile "$clientAlias.pem"

echo "- Adding Certificate Authority Certificate to Keystore"
keytool -import -trustcacerts -alias "$authorityAlias" -file "$authorityAlias.cer" -keystore "$clientAlias.p12" `
    -storepass "$certPassword" -noprompt

echo "- Adding Certificate to Keystore"
keytool -import -keystore "$clientAlias.p12" -file "$clientAlias.pem" -alias "$clientAlias" -keypass "$certPassword" `
    -storepass "$certPassword" -noprompt
rm "$clientAlias.csr"
# rm "$clientAlias.pem"

echo ""
echo "Generating the Trust Store and put the Client Certificate in it..."
keytool -importcert -alias "$authorityAlias" -file "$authorityAlias.cer" -storetype "$storeType" -keystore "$trustCertName.p12" `
    -storepass "$certPassword" -noprompt

echo ""
echo "Removing Public Key Files..."
# rm "$authorityAlias.cer"