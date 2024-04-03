# **Uso de SSH sobre AWS Systems Manager (SSM)**

# **Documentación: Uso de SSH sobre AWS Systems Manager (SSM) para Transferencia de Archivos a Instancias**

## **Introducción**

Esta documentación proporciona una guía paso a paso sobre cómo configurar y utilizar SSH y SCP sobre AWS Systems Manager (SSM) para la transferencia segura de archivos a instancias de AWS EC2. Esta metodología aprovecha las capacidades de SSM para administrar instancias sin la necesidad de una IP pública o una VPN.

## **Requisitos**

- AWS CLI instalado y configurado con credenciales adecuadas.
- Acceso a una instancia EC2 en AWS con SSM habilitado.
- Clave SSH (pública y privada).

## **Pasos de Configuración**

### **Paso 1: Configuración del Archivo SSH**

1. **Editar el archivo `~/.ssh/config`:**
    
    Este archivo configura el cliente SSH para utilizar un script de proxy que establece la conexión SSM.
    
    ```
    Host i-* mi-*
          IdentityFile ~/.ssh/id_rsa
          IdentitiesOnly yes
          ChallengeResponseAuthentication no
          ProxyCommand ~/.ssh/aws-ssm-ec2-proxy-command.sh %h %r %p
    ```
    
    - **`Host i-* mi-*`**: Se aplica a los hosts con nombres que comienzan con **`i-`** o **`mi-`**.
    - **`IdentityFile`**: Ruta a la clave privada SSH.
    - **`IdentitiesOnly`**, **`ChallengeResponseAuthentication`**: Configuraciones de autenticación SSH.
    - **`ProxyCommand`**: Comando para iniciar la conexión SSM.

### **Paso 2: Creación del Script de Proxy**

1. **Crear y configurar el script `aws-ssm-ec2-proxy-command.sh`:**
    
    Este script se encarga de agregar temporalmente tu clave pública SSH a la instancia EC2 y luego iniciar una sesión SSM.
    
    - Este script se ejecutará automáticamente cada vez que se inicie una conexión SSH o SCP a una instancia EC2.

```bash
#!/usr/bin/env sh
set -eu

ec2_instance_id="$1"
aws_region="us-west-2" # Asegúrate de ajustar esto a tu región AWS
ssh_user="$2"
ssh_port="$3"
ssh_public_key_path="${HOME}/.ssh/id_rsa_aws.pub"

# Asegúrate de que la clave pública SSH se inserta correctamente aquí
ssh_public_key="$(cat "${ssh_public_key_path}")"

# Añade temporalmente la clave pública SSH a la instancia EC2
aws ssm send-command \
  --instance-ids "${ec2_instance_id}" \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=[\"cd /home/${ssh_user}/.ssh || exit 1\", \"if ! grep -q -F '${ssh_public_key}' authorized_keys; then echo '${ssh_public_key}' >> authorized_keys; fi\"]" \
  --comment "Grant SSH access" \
  --region "${aws_region}"

# Inicia la sesión SSM SSH
aws ssm start-session \
  --target "${ec2_instance_id}" \
  --document-name "AWS-StartSSHSession" \
  --parameters "portNumber=${ssh_port}" \
  --region "${aws_region}"
```

### **Paso 3: Hacer Ejecutable el Script**

1. **Dar permisos de ejecución al script:**
    
    Ejecute el siguiente comando para hacer que el script sea ejecutable.
    
    ```bash
    chmod +x ~/.ssh/aws-ssm-ec2-proxy-command.sh
    ```
    

## **Paso 4: Instalación del Plugin de Session Manager de AWS**

Para establecer una conexión SSH a través de AWS Systems Manager, es necesario instalar el plugin de Session Manager de AWS en tu máquina local.

### **Instalación en macOS**

### **Opción 1: Uso del Instalador Empaquetado**

1. **Descargar el Instalador Empaquetado**:
    - Ejecuta el siguiente comando para descargar el instalador:
        
        ```bash
        curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
        ```
        
2. **Descomprimir el Paquete**:
    - Utiliza el comando **`unzip`** para extraer los archivos:
        
        ```bash
        unzip sessionmanager-bundle.zip
        ```
        
3. **Ejecutar el Comando de Instalación**:
    - Instala el plugin con el siguiente comando:
        
        ```bash
        sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
        
        ```
        
4. **Verificar la Instalación**:
    - Comprueba que el plugin se instaló correctamente ejecutando:
        
        ```bash
        session-manager-plugin
        ```
        

### **Opción 2: Uso del Instalador Firmado**

1. **Descargar el Instalador Firmado**:
    - Descarga el archivo usando **`curl`**:
        
        ```bash
        curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/session-manager-plugin.pkg" -o "session-manager-plugin.pkg"
        ```
        
2. **Ejecutar los Comandos de Instalación**:
    - Instala y configura el plugin con los siguientes comandos:
        
        ```bash
        sudo installer -pkg session-manager-plugin.pkg -target /
        sudo ln -s /usr/local/sessionmanagerplugin/bin/session-manager-plugin /usr/local/bin/session-manager-plugin
        ```
        
3. **Verificar la Instalación**:
    - Asegúrate de que el plugin está correctamente instalado:
        
        ```bash
        session-manager-plugin
        ```
        

Con el plugin de Session Manager instalado, ahora puedes usar SSH y SCP para conectarte y transferir archivos a tus instancias EC2 a través de AWS Systems Manager.

## **Uso**

Una vez configurado, puedes utilizar los comandos SSH y SCP de forma habitual, especificando el ID de la instancia EC2 como objetivo. El script y la configuración del SSH se encargarán de establecer la conexión a través de SSM.

### **Ejemplos de Comandos**

- **SSH a una instancia EC2:**
    
    ```bash
    
    ssh ec2-user@i-1234567890abcdef0
    
    ```
    
- **SCP para transferir archivos:**
    
    ```bash
    
    scp /path/to/local/file.txt ec2-user@i-1234567890abcdef0:/path/to/remote
    
    ```
    

## **Conclusión**

Esta configuración permite una conexión SSH y SCP segura y eficiente a instancias de AWS EC2 utilizando AWS Systems Manager, sin la necesidad de IPs públicas o configuraciones de red complejas. Es ideal para la administración segura de instancias en la nube.
