# Info
- php 8.3.7
- laravel 10.0
- SQL - процедуры и таблицы. В процедурах есть ссылки на шаблоны
- templatePages - html шаблоны в которые подставляются данные в формате json

# Сила одного
## Основной шаблон Анализ данных
- templatePages\rep_power_one_content.html
- движок для HightCharts https://www.highcharts.com/
- В него подставляются json данные при помощи движка twig в результате работы процедуры *rcsw_pro_rep_analyze_page* - полный расчет данных для отображения

- отдельный sankey chat c потоками templatePages\rep_power_one_content_sankey.html
- данные для нее отдельно формируются в процедуре *rcsw_pro_rep_powerone_page*


## Шаблон Моделирование "Сила одного"
- шаблон для подбора параметров / изменеия одного из 7 
- templatePages\rep_power_one_content.html (выполняется на javascript)
- Процедура подготовки: *rcsw_pro_rep_model_page*

## Шаблон Моделирование "Расчет"
- шаблон для Калькулятор эффективности инвестиционного проекта rep_calc_page_content.html и rep_calc_page_content.js
  
## Дополнительные шаблоны 
- шаблон для исходных данных spr_rawdata_page.html
