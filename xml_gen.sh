# !/bin/bash
# data: 30/06/2017
# Versão: 001
# Author: Jorge Bento <jorge.bento@sky.com.br>
# Company: SKY Brasil
# Departamento: Projetos – Compressão e Qualidade de Vídeo
# Descrição: xml_generator verifica novos conteúdos criados no Isilon pelo Ateme Titan
# e gera o xml de ingest no packager

#while true
#do

HORARIO="$(date)"

echo " Rodou o script as $HORARIO " >> /bin/xml_gen.log

LAST_CONTENT="$(ls /opt/envivio/mnt/str01.eng.local/poc_jitp/Out/001_titan_out -t | head -n1)"
Penultimo_conteudo="$(ls /opt/envivio/mnt/str01.eng.local/poc_jitp/Out/001_titan_out -t | head -n2 | tail -1)"

echo "	Penultimo =	$Penultimo_conteudo	            "
echo "	Ultimo =	$LAST_CONTENT	            "

PRECISA=false
ACABOU=false

gera_xml(){

echo "		Gerando mpd para $LAST_CONTENT   em  /opt/envivio/mnt/str01.eng.local/poc_jitp/Out/001_titan_out/$LAST_CONTENT "
#echo " aperte qualquer botão para continuar "
#read

cd /opt/envivio/haloDynamic/indexer/bin #Navega até a pasta onde roda o indexer

./indexer /opt/envivio/mnt/str01.eng.local/poc_jitp/Out/001_titan_out/$LAST_CONTENT/ #dispara o indexer sobre a última pasta criada

#echo " aperte qualquer botão para continuar "

Sucesso="$(find /opt/envivio/mnt/str01.eng.local/poc_jitp/Out/001_titan_out/$LAST_CONTENT/ -iname content.mpd)"


echo " achou $Sucesso "

cd /opt/envivio/mnt/str01.eng.local/poc_jitp/Out/001_titan_out/$LAST_CONTENT

mv content.mpd $LAST_CONTENT'_mpd.xml'

Sucesso_xml="$(find /opt/envivio/mnt/str01.eng.local/poc_jitp/Out/001_titan_out/$LAST_CONTENT/ -iname $LAST_CONTENT'_mpd.xml')"
echo " arquivo xml $Sucesso_xml "

echo "Criou o arquivo xml com sucesso em $Sucesso_xml " >> /bin/xml_gen.log

}

testa_necessidade (){
Sucesso="$(find /opt/envivio/mnt/str01.eng.local/poc_jitp/Out/001_titan_out/$LAST_CONTENT/ -iname content.mpd)"
Sucesso_xml="$(find /opt/envivio/mnt/str01.eng.local/poc_jitp/Out/001_titan_out/$LAST_CONTENT/ -iname $LAST_CONTENT'_mpd.xml')"
if [ -z "$Sucesso_xml"];
then
echo " vai gerar o xml"
PRECISA=true
else
echo " não vai gerar xml"
echo " arquivo mpd $Sucesso "
echo " arquivo xml $Sucesso_xml "
PRECISA=false
fi
echo " precisa $PRECISA "
}



verifica_fim_processamento (){
tamanho_um="$(du -B 1 /opt/envivio/mnt/str01.eng.local/poc_jitp/Out/001_titan_out/$LAST_CONTENT/ | cut -f1)" #medida do tamanho da pasta 10segundos antes
echo " tamanho_um = $tamanho_um "
sleep 20s
tamanho_dois="$(du -B 1 /opt/envivio/mnt/str01.eng.local/poc_jitp/Out/001_titan_out/$LAST_CONTENT/ | cut -f1)"
echo " tamanho_dois = $tamanho_dois"

while [ "$tamanho_um" != "$tamanho_dois" ]
do
echo "incrementando"
tamanho_um="$(du -B 1 /opt/envivio/mnt/str01.eng.local/poc_jitp/Out/001_titan_out/$LAST_CONTENT/ | cut -f1)" #medida do tamanho da pasta 
echo " tamanho_um = $tamanho_um "
sleep 30s
tamanho_dois="$(du -B 1 /opt/envivio/mnt/str01.eng.local/poc_jitp/Out/001_titan_out/$LAST_CONTENT/ | cut -f1)"
echo " tamanho_dois = $tamanho_dois"
done
ACABOU=true
echo " acabou $ACABOU  "
}

troca_codecs (){

cd  /opt/envivio/mnt/str01.eng.local/poc_jitp/Out/001_titan_out/$LAST_CONTENT/

sed -i -e 's/codecs="avc1.42E00D" width="640"/codecs="avc1.42E01E" width="640"/g' $LAST_CONTENT'_mpd.xml'
sed -i -e 's/codecs="avc1.42E00D" width="854"/codecs="avc1.42E01F" width="854"/g' $LAST_CONTENT'_mpd.xml'
sed -i -e 's/codecs="avc1.42E00D" width="1280"/codecs="avc1.42E01F" width="1280"/g' $LAST_CONTENT'_mpd.xml'

}

echo "  Penultimo =     $Penultimo_conteudo                 "
echo "  Ultimo =        $LAST_CONTENT               "


if [ "$LAST_CONTENT" != "$Penultimo_conteudo" ]
then
testa_necessidade
verifica_fim_processamento
if ($ACABOU && $PRECISA);then
echo " acabou $ACABOU  "
echo " precisa $PRECISA"
echo " validou as duas "
gera_xml
troca_codecs
else
echo " acabou $ACABOU  "
echo " precisa $PRECISA "
fi

else

echo "          Penultimo igual ao ultimo             "

fi

exit

