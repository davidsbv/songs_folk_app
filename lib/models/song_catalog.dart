/// Tipos de canción fallback local.
const List<String> songTypes = ['JOTA', 'SEGUIDILLA', 'OTRO'];

/// Subtipos por tipo (ej: para JOTA hay "RELIGIOSAS", "VARIAS", etc.).
const Map<String, List<String>> subtypesByType = {
  'JOTA': [
    'ENTRADAS', 'A LA MUJER', 'CALLES Y PLAZAS', 'ENAMORADOS', 'AUTORIDADES',
    'RELIGIOSAS', 'DE LOS PUEBLOS', 'ENTRE RONDADORES', 'DE ANIMALES', 'ESCATOLÓGICAS',
    'VARIAS', 'DE VENTANA', 'A LA ADOLESCENCIA', 'A LAS FIESTAS', 'A LOS QUINTOS',
    'AL CRISTO', 'A LOS HIJOS', 'A ESTACIONES DEL AÑO', 'JOCOSAS', 'VERDES',
    'PERSONAJES', 'DESPEDIDAS',
  ],
  'SEGUIDILLA': [
    'SEGUIDILLAS A LA VIRGEN', 'SEGUIDILLAS A LA MUJER', 'SEGUIDILLAS A LOS PUEBLOS',
  ],
};

/// Valor especial para el filtro "Todos los subtipos" en los dropdowns.
const String allSubtypesKey = '__TODOS_LOS_SUBTIPOS__';
