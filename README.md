# Omarchy Workspace Previews

Widget de Omarchy Quattro que muestra una vista previa espacial del escritorio al pasar el cursor por un número de espacio de trabajo. La tarjeta presenta el escritorio completo, no una lista de aplicaciones, y un clic en ella cambia a ese espacio. Sus colores siguen el tema activo.

## Instalar

```bash
omarchy plugin add https://github.com/jeancarlosg93/omarchy-workspace-previews.git --enable
omarchy restart shell
```

Al activarlo sustituye la entrada `omarchy.workspaces` existente. No requiere los otros dos plugins. La vista previa depende de Hyprland y de las API de Omarchy Quattro.

Para volver al widget original: `omarchy plugin disable jeanc.workspaces`. Para actualizar: `omarchy plugin update jeanc.workspaces`.

El widget deriva de [Omarchy](https://github.com/omacom/omarchy), bajo licencia MIT. Véase [LICENSE](LICENSE).
