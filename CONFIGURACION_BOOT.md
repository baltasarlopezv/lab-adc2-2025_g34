# Configuración de arranque

Se modificó el archivo `boot_sd/config.txt` para indicar explícitamente qué
kernel debe cargar la Raspberry Pi:

```ini
arm_64bit=1
kernel=kernel8.img
```

El cambio fue necesario porque, con la configuración original, la Raspberry no
estaba cargando correctamente nuestro programa y mostraba una pantalla
multicolor. En cambio, QEMU sí podía ejecutar la imagen sin problemas.

La nueva configuración le indica a la Raspberry que:

- use el modo de 64 bits;
- cargue el archivo `kernel8.img`, que es el kernel generado para este
  proyecto.

No se modificó el código del programa ni los demás archivos de arranque. El
cambio solamente permite que la Raspberry seleccione y ejecute correctamente
el kernel del ejercicio 2.
