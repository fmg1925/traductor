# Trilingo — README

## ¿Qué es?
Trilingo es una app de traducción con interfaz en Flutter (Web/Android/Escritorio) que permite:
- Traducir texto completo entre múltiples idiomas.
- Tocar palabras para ver su significado “al vuelo” (estilo Duolingo).
- Cachear traducciones de palabras localmente para respuestas instantáneas.

## Backend
**Flask actúa como un intermediario (proxy) hacia LTEngine**.  
- Recibe peticiones del cliente (traducción de texto o de una palabra).
- Normaliza parámetros (idioma origen/destino, auto-detección).
- Reenvía la solicitud a **LTEngine** y devuelve una respuesta simple y consistente al frontend.
- Aplica CORS selectivo (solo para las rutas necesarias).

> Nota: LTEngine es el motor de traducción/auto-detección subyacente. Flask no traduce: solo valida, enruta y formatea las respuestas.

## Frontend (Flutter)
- Campo de texto y **dropdowns** para elegir idioma de origen y destino.
- Vista de resultados con:
  - **Original (idioma detectado)**
  - **Traducción (idioma destino)**
- **Tap-to-translate** por palabra tanto en el texto original como en la traducción (traducción directa e inversa).
- **Caché local** de traducciones de palabras con almacenamiento persistente para acelerar consultas repetidas.
- Compatibilidad multiplataforma (Web/Android/Escritorio) con detección de entorno para dirigir las solicitudes al backend.

## Flujo
1. El usuario escribe (o genera) una frase.
2. El frontend envía una solicitud al backend Flask.
3. **Flask** reenvía la petición a **LTEngine**, recopila resultados (incl. idioma detectado) y los **devuelve en un formato unificado**.
4. El frontend muestra el original + traducción, y permite tocar palabras para ver su significado contextual.
5. Las traducciones de palabras se **cachean** localmente para futuras consultas.

## Objetivos del proyecto
- Ofrecer una experiencia de aprendizaje/traducción rápida y clara.
- Separar responsabilidades: **Flutter (UI/UX)** y **Flask (intermediario)** frente a **LTEngine (motor de traducción)**.
- Mantener respuestas consistentes y fácilmente consumibles por el cliente.

## Próximos pasos
- Mejores mensajes de error y tolerancia a fallos.
- Estadísticas de uso del caché y gestión avanzada (expiración/limpieza).
- Soporte ampliado de idiomas y configuraciones de usuario.
- Tests end-to-end y CI para asegurar calidad en cambios futuros.
