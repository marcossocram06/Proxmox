#!/bin/bash

# Variáveis
versao="nil"
vmID="nil"

echo "############## Início do Script ##############"

## Verificando se o diretório temporário está disponível..."
if [ -d /root/temp ]
then
    echo "-- Diretório existe!"
else
    echo "-- Criando diretório temporário!"
    mkdir /root/temp
fi

# Solicitar ao usuário a versão
echo "## Preparando para download da imagem e criação da VM!"
read -p "Por favor, insira a versão do CHR a ser implantada (6.38.2, 6.40.1, etc):" versao

# Verificar se a imagem está disponível e fazer o download, se necessário
if [ -f /root/temp/chr-$versao.img ]
then
    echo "-- Imagem CHR está disponível."
else
    echo "-- Fazendo download do arquivo de imagem CHR $versao."
    cd /root/temp
    echo "---------------------------------------------------------------------------"
    wget https://download.mikrotik.com/routeros/$versao/chr-$versao.img.zip
    unzip chr-$versao.img.zip
    echo "---------------------------------------------------------------------------"
fi

# Listar as VMs existentes e solicitar o vmID
echo "== Listando as VMs neste hipervisor!"
qm list
echo ""
read -p "Por favor, digite o ID da VM livre para usar:" vmID
echo ""

# Criar diretório de armazenamento para a VM, se necessário
if [ -d /var/lib/vz/images/$vmID ]
then
    echo "-- Diretório da VM existe! Idealmente, tente outro ID de VM!"
    read -p "Por favor, digite o ID da VM livre para usar:" vmID
else
    echo "-- Criando diretório de imagem da VM!"
    mkdir /var/lib/vz/images/$vmID
fi

# Criando imagem qcow2 para CHR.
echo "-- Convertendo imagem para formato qcow2"
qemu-img convert \
    -f raw \
    -O qcow2 \
    /root/temp/chr-$versao.img \
    /var/lib/vz/images/$vmID/vm-$vmID-disk-1.qcow2

# Criando VM
echo "-- Criando nova VM CHR"
qm create $vmID \
  --name chr-$versao \
  --net0 virtio,bridge=vmbr0 \
  --bootdisk virtio0 \
  --ostype l26 \
  --memory 256 \
  --onboot no \
  --sockets 1 \
  --cores 1 \
  --virtio0 local:$vmID/vm-$vmID-disk-1.qcow2

echo "############## Fim do Script ##############"
