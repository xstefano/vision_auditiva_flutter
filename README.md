#  Vision Auditiva
`ASISTENTE VIRTUAL DE AYUDA PARA PERSONAS CON DISCAPACIDAD VISUAL EN UNA APLICACIÓN MÓVIL`

<div style="display: flex;">
  <div style="flex: 1; background-color: #f2f2f2; padding: 10px;">
    <h2>Resumen</h2>
    La aplicación <strong>Vision Auditiva</strong> fue creada con el propósito de asistir como ayuda extra para personas con <strong>discapacidad visual</strong> mediante una foto tomada desde el aplicativo.
    <br><br>
    <strong> "Escucha lo que no puedes ver"</strong> aplicación permite al usuario reconocer mediante la cámara de un celular, los objetos, los rostros, estimar el número de personas siempre y cuando el usuario lo solicite y además podrá también reconocer textos, todo esto a través de mensajes por voz, solicitando como por ejemplo "describa imagen" o "leer texto" lo cual los podrá leer o escribir y mandar esa salida mediante un audio al celular o dispositivo que se esté usando. 
    <br><br> <br>
    La posicion de los botones está pensado para una facil manipulacion
    <br>
    La primera imagen que aparece en la app es temporal, se reemplazará por la foto tomada por el usuario.
  </div>
  <div style="flex: 1;">
    <img src="https://i.imgur.com/xr0vGn6.png" width="210">
  </div>
</div>

##  Funcionamiento
```
1. El usuario podrá realizar la foto (cámara trasera) pulsando una vez el botón de la izquierda, esa imagen estará guardada en el servidor para analizar con los metodos siguientes.

2. El botón de la derecha se usa para pedir mediante voz que metodo se ejecutará para analizar la imagen (metodos explicados más adelante).

3. Una vez el aplicativo escucha el metodo solicitado empezará a enviar la peticion al servidor y retornará lo solicitado mediante audio.

```
` < Poner un video de youtube de su funcionamiento > `

##  Metodos del Aplicativo

Si el aplicativo escucha que se habló alguno de los metodos ejecutará su respectiva acción:

|     Metodo             |                            Funcionamiento                            |
| :------------:        | :-----------------------------------------------------------: |
|   `Describe Imagen`   |    Analiza la foto para llegar a una conclusion para describir la imagen     |
|   `Analiza Rostro` |     Detecta cuantos rostros hay en la foto para calcular su género y edad de cada rostro |
| `Lee Texto`          |       Lee el texto que hay en la foto tomada       |
|  `Detecta Objeto`     |   Detecta los objetos para devolver en un listado los objetos y su cantidad cantidad |


##   Ejemplo de los metodos


|         Foto Tomada          |                     Metodo Llamado                       |                 Resultado   |
| :------------------------: | :----------------------------------------------: | :------------------------------------------------------------------------------------------------: |
|<img src="https://i.imgur.com/aGYahh4.jpeg" width="300">  |   `Describe Imagen`     |          Un grupo de personas jugando en el parque   |
|<img src="https://i.imgur.com/zYKHtZG.jpg" width="250">   |    `Analiza Rostro`   |     Rostro 1 : Género=MascuIino, Rango edad = (25-32)  |
|<img src="https://i.imgur.com/Xh6dRui.png" width="250">   |  `Leer Texto  `  | LAS NIÑAS YA NO QUIEREN SER PRINCESAS QUIEREN SER ALCALDESAS|
|<img src="https://i.imgur.com/0Jp4Vi9.jpg" width="200">   | ` Detecta Objeto` | Se han detectado los siguientes objetos: 2 persona y 1 Tren subterráneo|
|



##  Tecnologias Usadas

`especificar las tecnologias usadas` 

<img src="https://i.imgur.com/mLfgXC1.png" width="500">
