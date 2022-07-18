//  Обработка получает заказы с сайта, создаёт новый заказ в справочнике и 
//  формирует расходные накладные на основе полученных данных.
//
//

Перем Соединение, Conect, ПокупателиОнлайн, КолЗаказы, Драйвер, Сервер, Кодировка ,База, Логин,Пароль, табЗаказ, табТовар, ВыбКлиенты, Параметр Экспорт;

// 
//   Читает настройки из файла конфигурации. Записавает данные в глобальные переменные
//
//

Процедура ЗагрузитьНастройки()
	ФС1=СоздатьОбъект("ФС");
	Если ФС1.СуществуетФайл(КаталогИБ()+"settings.inf") =1 тогда
		Файл = СоздатьОбъект("Текст");
		Файл.Открыть(КаталогИБ()+"settings.inf");
		Драйвер  = СокрЛП(Файл.ПолучитьСтроку(1)); //  "MySQL ODBC 5.3 Unicode Driver"
		Сервер  = СокрЛП(Файл.ПолучитьСтроку(2));  //  "109.94.209.16"
		База  = СокрЛП(Файл.ПолучитьСтроку(3));    //  "caseroom_db"
		Логин  = СокрЛП(Файл.ПолучитьСтроку(4));   //  "caseroom_db"
		Пароль = СокрЛП(Файл.ПолучитьСтроку(5));   //  "мой_пасс"
		Если Файл.ПолучитьСтроку(6)="1" тогда
			Кодировка = 1;
		КонецЕсли;
		Если СокрЛП(Файл.ПолучитьСтроку(7))="1" тогда
			рн = 1;
		КонецЕсли;
		// Клиент по умолчанию используемый для формирования накладных
		Если СокрЛП(Файл.ПолучитьСтроку(8))<>"0" тогда
			спрК = СоздатьОбъект("Справочник.Клиенты");
			Если спрК.НайтиПоКоду(СокрЛП(Файл.ПолучитьСтроку(8))) = 1 тогда
				ВыбКлиенты = спрК.ТекущийЭлемент();
			Иначе
				ВыбКлиенты = " ";
			КонецЕсли;
		КонецЕсли;
		// Основной Склад 
		Если СокрЛП(Файл.ПолучитьСтроку(9))<>"0" тогда
			спрС = СоздатьОбъект("Справочник.Склады");
			Если спрС.НайтиПоКоду(СокрЛП(Файл.ПолучитьСтроку(9))) = 1 тогда
				ВыбСклады = спрС.ТекущийЭлемент();
			Иначе
				ВыбСклады = " ";
			КонецЕсли;
		КонецЕсли;
		Если СокрЛП(Файл.ПолучитьСтроку(10))<>"0" тогда
			спрФ = СоздатьОбъект("Справочник.Фирмы");
			Если спрФ.НайтиПоКоду(СокрЛП(Файл.ПолучитьСтроку(10))) = 1 тогда
				ВыбФирма = спрФ.ТекущийЭлемент();
			Иначе
				ВыбФирма = " ";
			КонецЕсли;
		КонецЕсли;
		morelocale = СокрЛП(Файл.ПолучитьСтроку(11)); 	
		ОснЛокаль = СокрЛП(Файл.ПолучитьСтроку(12));  		
		ДопЛокаль = СокрЛП(Файл.ПолучитьСтроку(13)); 	
		Кей = СокрЛП(Файл.ПолучитьСтроку(14));        		
		АйдиЯзык = СокрЛП(Файл.ПолучитьСтроку(15));
		Прокси = СокрЛП(Файл.ПолучитьСтроку(16)); 
		пСервер =  СокрЛП(Файл.ПолучитьСтроку(17));
		пПорт =  СокрЛП(Файл.ПолучитьСтроку(18));
		ФтпСервер =  СокрЛП(Файл.ПолучитьСтроку(19));
		ФтпЛогин =  СокрЛП(Файл.ПолучитьСтроку(20));
		ФтпПароль =  СокрЛП(Файл.ПолучитьСтроку(21));
		КаталогФтп =  СокрЛП(Файл.ПолучитьСтроку(22));
		КаталогФтпФото =  СокрЛП(Файл.ПолучитьСтроку(23));
	КонецЕсли;
КонецПроцедуры

//
// Устанавливает соединения с базой сайта.
//
//

Процедура УстановкаСоединения()
	ЗагрузитьНастройки();
	Соединение = СоздатьОбъект("ADODB.Connection");
	Если Кодировка = 1 тогда
		КодСтр = "STMT=set character_set_results=cp1251;"
	иначе
		КодСтр = "";
	Конецесли;
	СтрокаСоединения = "DRIVER="+СокрЛП(Драйвер)+";SERVER="+СокрЛП(Сервер)+";DataBase="+СокрЛП(База)+";UID="+СокрЛП(Логин)+";PWD="+СокрЛП(Пароль)+";"+СокрЛП(КодСтр);
	Соединение.ConnectionString = (СтрокаСоединения);
	Попытка
		Соединение.Open();
		Conect=1;
	Исключение
		Conect=0;
		Сообщить("Не могу подключиться к базе!!!");
	КонецПопытки;
КонецПроцедуры

//
//  Получает заказы из базы MySQL используя MySQL Connector
//  и записывает в табЗаказ (ТаблицаЗначений, глобальная область видимости)
//

Процедура ЗаказыПолучить()
	УстановкаСоединения();
	Заказ = Соединение.Execute(
	"SELECT 
	|po.order_id,
	|`customer_id`,
	|`firstname`,
	|`lastname`,
	|`email`,
	|`telephone`,
	|`payment_method`,
	|`payment_code`,
	|`shipping_firstname`,
	|`shipping_lastname`,
	|`shipping_address_1`,
	|`shipping_city`,
	|`shipping_postcode`,
	|`shipping_zone`,
	|`shipping_code`,
	|`shipping_method`,
	|`comment`,
	|CAST(po.total as char) AS total,
	|`order_status_id`,
	|`ip`,
	|po.date_added 
	|FROM `oc_order` po WHERE order_status_id <> 0 ORDER BY `order_id` ASC"
	);
	табЗаказ = СоздатьОбъект("ТаблицаЗначений");
	табЗаказ.НоваяКолонка("order_id",,,"order_id",,,,);
	табЗаказ.НоваяКолонка("customer_id",,,"customer_id",,,,);
	табЗаказ.НоваяКолонка("firstname",,,"Имя",,,,);
	табЗаказ.НоваяКолонка("lastname",,,"Фамилия",,,,);
	табЗаказ.НоваяКолонка("email",,,"email",,,,);
	табЗаказ.НоваяКолонка("telephone",,,"telephone",,,,);
	табЗаказ.НоваяКолонка("payment_method",,,"Метод оплаты",,,,);
	табЗаказ.НоваяКолонка("payment_code",,,"Код оплаты",,,,);
	табЗаказ.НоваяКолонка("shipping_method",,,"Метод отправки",,,,);
	табЗаказ.НоваяКолонка("shipping_firstname",,,"Имя получателя",,,,);	
	табЗаказ.НоваяКолонка("shipping_lastname",,,"Фамилия получателя",,,,);
	табЗаказ.НоваяКолонка("shipping_address_1",,,"Адрес доставки",,,,);
	табЗаказ.НоваяКолонка("shipping_city",,,"Город",,,,);
	табЗаказ.НоваяКолонка("shipping_postcode",,,"Индекс/Отделение",,,,);	
	табЗаказ.НоваяКолонка("shipping_zone",,,"Область",,,,);	
	табЗаказ.НоваяКолонка("shipping_code",,,"Метод доставки",,,,);	
	табЗаказ.НоваяКолонка("comment",,,"Комментарий",,,,);
	табЗаказ.НоваяКолонка("total",,,"Сумма",,,,);
	табЗаказ.НоваяКолонка("order_status_id",,,"Статус заказа",,,,);
	табЗаказ.НоваяКолонка("ip",,,"ip Пользователя",,,,);	
	табЗаказ.НоваяКолонка("po_date_added",,,"Дата заказа",,,,);	
	табТовар = СоздатьОбъект("ТаблицаЗначений");
	табТовар.НоваяКолонка("order_id",,,"order_id",,,,);
	табТовар.НоваяКолонка("product_id",,,"product_id",,,,);
	табТовар.НоваяКолонка("sku",,,"sku",,,,);
	табТовар.НоваяКолонка("name",,,"name",,,,); 
	табТовар.НоваяКолонка("quantity",,,"quantity",,,,); 
	табТовар.НоваяКолонка("price",,,"price",,,,); 
	табТовар.НоваяКолонка("total",,,"total",,,,); 
	НомСтрок = 0;
	НомСтрокТов = 0;
	Пока Заказ.Eof() = 0 Цикл
		//Состояние("Получение данных");
		НомСтрок = НомСтрок + 1;
		табЗаказ.НоваяСтрока(НомСтрок);
		табЗаказ.УстановитьЗначение(НомСтрок,"order_id",Заказ.Fields.Item("order_id").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"customer_id",Заказ.Fields.Item("customer_id").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"firstname",Заказ.Fields.Item("firstname").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"lastname",Заказ.Fields.Item("lastname").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"email",Заказ.Fields.Item("email").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"telephone",Заказ.Fields.Item("telephone").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"payment_method",Заказ.Fields.Item("payment_method").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"payment_code",Заказ.Fields.Item("payment_code").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"total",Заказ.Fields.Item("total").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"shipping_method",Заказ.Fields.Item("shipping_method").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"shipping_code",Заказ.Fields.Item("shipping_code").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"shipping_firstname",Заказ.Fields.Item("shipping_firstname").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"shipping_lastname",Заказ.Fields.Item("shipping_lastname").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"shipping_address_1",Заказ.Fields.Item("shipping_address_1").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"shipping_city",Заказ.Fields.Item("shipping_city").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"shipping_postcode",Заказ.Fields.Item("shipping_postcode").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"shipping_zone",Заказ.Fields.Item("shipping_zone").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"comment",Заказ.Fields.Item("comment").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"order_status_id",Заказ.Fields.Item("order_status_id").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"ip",Заказ.Fields.Item("ip").value);
		табЗаказ.УстановитьЗначение(НомСтрок,"po_date_added",Заказ.Fields.Item("date_added").value);
		Товар = Соединение.Execute(
		"SELECT 
		|order_id, 
		|ocp.sku, 
		|oco.product_id, 
		|oco.name, 
		|oco.quantity, 
		|CAST(oco.price as char) AS price, 
		|CAST(oco.total as char) AS total  
		|FROM `oc_order_product` oco 
		|LEFT JOIN oc_product ocp ON ocp.product_id=oco.`product_id` 
		|WHERE `order_id` ="+Заказ.Fields.Item("order_id").value+" 
		|ORDER BY `order_id`  DESC"
		);
		Пока Товар.Eof() = 0 Цикл
			НомСтрокТов = НомСтрокТов + 1;
			табТовар.НоваяСтрока(НомСтрокТов);
			табТовар.УстановитьЗначение(НомСтрокТов,"order_id",Товар.Fields.Item("order_id").value);
			табТовар.УстановитьЗначение(НомСтрокТов,"sku",Товар.Fields.Item("sku").value);
			табТовар.УстановитьЗначение(НомСтрокТов,"product_id",Товар.Fields.Item("product_id").value);
			табТовар.УстановитьЗначение(НомСтрокТов,"name",Товар.Fields.Item("name").value); 
			табТовар.УстановитьЗначение(НомСтрокТов,"quantity",Товар.Fields.Item("quantity").value);
			табТовар.УстановитьЗначение(НомСтрокТов,"price",Товар.Fields.Item("price").value);
			табТовар.УстановитьЗначение(НомСтрокТов,"total",Товар.Fields.Item("total").value);
			Товар.MoveNext();
		КонецЦикла;
		Заказ.MoveNext();
	КонецЦикла;
КонецПроцедуры  

//
//
// Создаёт елементы в справочнике "Задачи"(Изначально создавал для создания текущих задач)
// табЗаказ - ТаблицаЗначений с глобальной областью видимости. Заполняется в процедуре ЗаказыПолучить()  
//
//

Процедура ЗаказыЗаписать()
	спрЗаказы=СоздатьОбъект("Справочник.Задачи");
	спрСтат = СоздатьОбъект("Справочник.СтатусЗаказа");
	спрСтр = СоздатьОбъект("Справочник.Сотрудники");
	спрЗаказы.ИспользоватьДату(РабочаяДата());
	НомСтрок = 0;
	Для ы=1 по табЗаказ.КоличествоСтрок() Цикл
		Если спрЗаказы.НайтиПоРеквизиту("id",табЗаказ.ПолучитьЗначение(ы,"order_id"),1) = 0 тогда
			Тел = СокрЛП(табЗаказ.ПолучитьЗначение(ы,"telephone"));
			спрЗаказы.Новый();
			спрЗаказы.id = табЗаказ.ПолучитьЗначение(ы,"order_id");
			спрЗаказы.Наименование = табЗаказ.ПолучитьЗначение(ы,"lastname")+" "+табЗаказ.ПолучитьЗначение(ы,"firstname"); 
			спрЗаказы.Фамилия = табЗаказ.ПолучитьЗначение(ы,"lastname"); 
			спрЗаказы.Телефон = Прав(Тел,10); 
			спрЗаказы.эмаил = табЗаказ.ПолучитьЗначение(ы,"email"); 
			спрЗаказы.зДата = табЗаказ.ПолучитьЗначение(ы,"po_date_added"); 
			Если спрСтр.НайтиПоКоду("5",0) = 1 тогда
				спрЗаказы.Менеджер = спрСтр.ТекущийЭлемент();
			КонецЕсли;
			Если спрСтат.НайтиПоРеквизиту("АйДи",табЗаказ.ПолучитьЗначение(ы,"order_status_id"),1) = 1 тогда
				спрЗаказы.СтатусЗаказа = спрСтат.ТекущийЭлемент();
			КонецЕсли;
			Если СокрЛП(табЗаказ.ПолучитьЗначение(ы,"payment_code")) = "privat" тогда
				спрЗаказы.МетодОплаты = Перечисление.ВидыТорговли.ПереводНаКарту;
			КонецЕсли;
			Если СокрЛП(табЗаказ.ПолучитьЗначение(ы,"payment_code")) = "cod" тогда
				спрЗаказы.МетодОплаты = Перечисление.ВидыТорговли.Наложка;
			КонецЕсли;
			Если СокрЛП(табЗаказ.ПолучитьЗначение(ы,"payment_code")) = "wayforpay" тогда
				спрЗаказы.МетодОплаты = Перечисление.ВидыТорговли.WayForPay;
			КонецЕсли;
			Если СокрЛП(табЗаказ.ПолучитьЗначение(ы,"shipping_code")) = "novaposhta.novaposhta" тогда
				нп=1;
				спрЗаказы.МетодДоствки = Перечисление.ВидДоставки.НоваяПочта;
			КонецЕсли;
			Если СокрЛП(табЗаказ.ПолучитьЗначение(ы,"shipping_code")) = "avtolux.avtolux" тогда
				спрЗаказы.МетодДоствки = Перечисление.ВидДоставки.УкрПочта;
			КонецЕсли;
			Если СокрЛП(табЗаказ.ПолучитьЗначение(ы,"shipping_code")) = "pickup.pickup" тогда
				спрЗаказы.МетодДоствки = Перечисление.ВидДоставки.Самовывоз;
			КонецЕсли;
			спрЗаказы.Область = табЗаказ.ПолучитьЗначение(ы,"shipping_city");// табЗаказ.ПолучитьЗначение(ы,"shipping_zone");
			спрЗаказы.Город = табЗаказ.ПолучитьЗначение(ы,"shipping_city");
			спрЗаказы.ИндексОтдел = табЗаказ.ПолучитьЗначение(ы,"shipping_postcode");
			Если нп =1 тогда 
				РефГород = табЗаказ.ПолучитьЗначение(ы,"shipping_address_1");
				Город = Лев(РефГород,Найти(РефГород,";")-1);
				Отделение = Сред(РефГород,Найти(РефГород,";")+1);
				спрЗаказы.РефОбл = Город;
				спрЗаказы.РефОтделения = Отделение; 
		
				спрЗаказы.Адрес = СокрЛП(табЗаказ.ПолучитьЗначение(ы,"shipping_city"))+", "+СокрЛП(табЗаказ.ПолучитьЗначение(ы,"shipping_postcode")); 
			иначе
				спрЗаказы.Адрес = табЗаказ.ПолучитьЗначение(ы,"shipping_address_1");
			КонецЕсли;
			спрЗаказы.Статус = Перечисление.ДаНет.Нет;
			//спрЗаказы.Адрес = табЗаказ.ПолучитьЗначение(ы,"shipping_address_1");
			спрЗаказы.ТелефонПол = спрЗаказы.Телефон;
			спрЗаказы.Плательщик = Перечисление.Плательщик.Recipient;
			спрЗаказы.Сумма = Формат(табЗаказ.ПолучитьЗначение(ы,"total"),"Ч12.2");
			спрКл = СоздатьОбъект("Справочник.Клиенты");
			спрКл.ИспользоватьДату(РабочаяДата());
			Если (спрКл.НайтиПоРеквизиту("Email",табЗаказ.ПолучитьЗначение(ы,"email"),1) = 1) или (спрКл.НайтиПоРеквизиту("Телефоны",табЗаказ.ПолучитьЗначение(ы,"telephone"),1) = 1)  тогда
				спрЗаказы.зКлиент = спрКл.ТекущийЭлемент();
			иначе
				Родитель = ВыбКлиенты.Родитель;
				спрКл.ИспользоватьРодителя(Родитель);
				спрКл.Новый();
				спрКл.Код_ = Строка(табЗаказ.ПолучитьЗначение(ы,"customer_id"));
				спрКл.Наименование = Строка(табЗаказ.ПолучитьЗначение(ы,"firstname")+" "+табЗаказ.ПолучитьЗначение(ы,"lastname")); 
				спрКл.ПолнНаименование = спрКл.Наименование;
				спрКл.Адрес = Строка(табЗаказ.ПолучитьЗначение(ы,"shipping_zone"))+" "+Строка(табЗаказ.ПолучитьЗначение(ы,"shipping_city"))+" "+Строка(табЗаказ.ПолучитьЗначение(ы,"shipping_address_1")); 
				спрКл.ФизАдрес = спрКл.Адрес;
				спрКл.Телефоны = табЗаказ.ПолучитьЗначение(ы,"telephone");
				спрКл.ВалютаВзаиморасчетов = Константа.Гривня;
				спрКл.ВидТорговли = Перечисление.ВидыТорговли.Предоплата;
				спрКл.ВозСкидка = Перечисление.ВариантыСкидок.БезСкидки;
				спрКл.ЗапрВыдачи = Перечисление.ДаНет.Нет; 
				спрКл.ТипЦен = Перечисление.ТипыЦен.Категория2;
				спрКл.Email = табЗаказ.ПолучитьЗначение(ы,"email");
				спрКл.Записать();
				спрЗаказы.зКлиент = спрКл.ТекущийЭлемент();
			КонецЕсли;
			спрЗаказы.зДата = табЗаказ.ПолучитьЗначение(ы,"po_date_added");  
			спрЗаказы.Описание = табЗаказ.ПолучитьЗначение(ы,"comment");
			//++++++++++++++++++++++++++++++++++++++++  Список проданных товаров сворачиваю в строку и записываю в реквизит, который имеет тип - строка
			Если табТовар.КоличествоСтрок() <> 0 тогда
				табТовар.ВыбратьСтроки();
				_Строка = СоздатьОбъект("СписокЗначений");
				пр2 = 0;
				Для а = 1 По табТовар.КоличествоСтрок() Цикл
					пр1 = СокрЛП(табТовар.ПолучитьЗначение(а,"order_id")); 
					пр2 = СокрЛП(спрЗаказы.id);
					Если пр1 = пр2 тогда
						_Значение = "sku#"+Строка(СокрЛП(табТовар.ПолучитьЗначение(а,"sku")));
						_Строка.ДобавитьЗначение(_Значение);
						_Значение = "pid#"+Строка(СокрЛП(табТовар.ПолучитьЗначение(а,"product_id")));
						_Строка.ДобавитьЗначение(_Значение);
						_Значение = "nam#"+Строка(СокрЛП(табТовар.ПолучитьЗначение(а,"name")));
						_Строка.ДобавитьЗначение(_Значение);
						_Значение = "qua#"+Строка(СокрЛП(табТовар.ПолучитьЗначение(а,"quantity")));
						_Строка.ДобавитьЗначение(_Значение);
						_Значение = "pri#"+Строка(СокрЛП(табТовар.ПолучитьЗначение(а,"price")));
						_Строка.ДобавитьЗначение(_Значение);                                     
					КонецЕсли;
				КонецЦикла;
				спрЗаказы.Товар = _Строка.ВСтрокуСРазделителями(); 
			КонецЕсли;
			//++++++++++++++++++++++++++++++++++++++++
			спрЗаказы.Записать();
			Сообщить(Шаблон("Новый заказ: [спрЗаказы.id] Имя: [спрЗаказы.Наименование] [спрЗаказы.Фамилия] сумма: [Формат(табЗаказ.ПолучитьЗначение(ы,""total""),""Ч12.2"")]"));
			Параметр.ДобавитьЗначение("Новый заказ: "+спрЗаказы.id);
			Параметр.ДобавитьЗначение("ФИО: "+спрЗаказы.Фамилия+" "+спрЗаказы.Наименование);
			Параметр.ДобавитьЗначение("Телефон: "+спрКл.Телефоны);
			Параметр.ДобавитьЗначение("Сумма: "+Формат(табЗаказ.ПолучитьЗначение(ы,"total"),"Ч12.2"));
			Параметр.ДобавитьЗначение("----------------------------");
		КонецЕсли;
	КонецЦикла;
КонецПроцедуры

// Формимует документ "РасходнаяНакладная" на основе данных полученных с сайта
//
// var ДанныеДляДокумента - Таблица значений 
// 	Колонка("sku",,30,," ",2,,);
//  Колонка("quan",,,,,5,,);
//	Колонка("price",,,,"Наименование",35,,);
//  
//
Процедура СформироватьНакладную(ДанныеДляДокумента)
	КонтекстФормы2 = "";
	спрСтр = СоздатьОбъект("Справочник.Сотрудники");
	_Клиент = ДанныеДляДокумента.ПолучитьЗначение(1,"sku");
	Заказ = ДанныеДляДокумента.ПолучитьЗначение(2,"sku"); 
	КодМенеджер = ДанныеДляДокумента.ПолучитьЗначение(1,"price");  
	спрКлиент = СоздатьОбъект("Справочник.Клиенты");
	спрКлиент.ИспользоватьДату(РабочаяДата());
	Если спрКлиент.НайтиПоКоду(_Клиент,0) = 1 тогда
		Клиент = спрКлиент.ТекущийЭлемент();
	КонецЕсли;
	НачатьТранзакцию();
	док = СоздатьОбъект("Документ.РасходнаяНакладная"); 
	спрТов = СоздатьОбъект("Справочник.ТМЦ");
	спрТов.ИспользоватьДату(РабочаяДата());
	док.Новый();
	//	Если ПустоеЗначение(ДанныеДляДокумента.ПолучитьЗначение(2,"дата")) = 1 тогда
	док.ДатаДок=РабочаяДата(); 
	//	иначе
	//		док.ДатаДок = ДанныеДляДокумента.ПолучитьЗначение(2,"дата")
	//	КонецЕсли;
	//	док.НомерДок = Лев(ИмяПользователя(),1)+"_"+док.НомерДок; 
	//    Сообщить(док.НомерДок);
	док.Клиент = Клиент;
	док.Валюта = док.Клиент.ВалютаВзаиморасчетов;
	Если Клиент.ТипКонтрагента = Перечисление.ТипКонтрагента.ТТ тогда
		спрСклад = СоздатьОбъект("Справочник.Склады");
		Если спрСклад.НайтиПоНаименованию(Клиент.Наименование,0,1) = 1 тогда
			док.Склад = спрСклад.ТекущийЭлемент();
		КонецЕсли;
	иначе
		док.Склад = Константа.БазСклад;
	КонецЕсли;
	
	док.ВидУчета = Перечисление.ВидыУчета.Совместный;
	Если спрСтр.НайтиПоКоду(СокрЛП(КодМенеджер),0) = 1 тогда
		док.Менеджер = спрСтр.ТекущийЭлемент();
	КонецЕсли;
	//док.Менеджер = док.Клиент.Менеджер;
	док.ВидНДС = Константа.БазНДС.Получить(РабочаяДата()); 
	док.ВидТорговли = док.Клиент.ВидТорговли;
	док.ТипЦен = док.Клиент.ТипЦен;
	док.Курс = КурсДляВалюты(док.Валюта,док.ДатаДок);
	док.СчетПокупателя = СчетПоКоду("62.2");
	док.Фирма = Константа.БазФирма.Получить(ТекущаяДата());
	док.Отпустил = Константа.БазОтпустил;
	док.СубконтоВалДох = Константа.БазВалДоход;
	док.Основание = Строка("Создан на основании заказа "+Заказ);
	НомСтрок = 0;
	НомСтрокДок = 0;
	Для ы = 1 По ДанныеДляДокумента.КоличествоСтрок() Цикл
		НомСтрокДок = НомСтрокДок+1;
		Код = СокрЛП(ДанныеДляДокумента.ПолучитьЗначение(НомСтрокДок,"sku")); 
		Количество = СокрЛП(ДанныеДляДокумента.ПолучитьЗначение(НомСтрокДок,"quan"));  
		ЦенаПродажи = СокрЛП(ДанныеДляДокумента.ПолучитьЗначение(НомСтрокДок,"price"));  
		Если НомСтрокДок > 2 тогда
			sku = СокрЛП(Код);
			//Состояние(Шаблон("Обработка строки [НомСтрокДок] поиск: [sku]"));
			Если спрТов.НайтиПоКоду(sku,0) = 1 тогда
				НомСтрок = НомСтрок+1;
				док.НоваяСтрока();
				док.КодТов = спрТов.КодТов;
				док.ШтрихКод = спрТов.ШтрихКод;
				док.ТМЦ = спрТов.ТекущийЭлемент();
				док.Кво = Количество;
				спрЕд = СоздатьОбъект("Справочник.ЕдИзм");
				спрЕд.ИспользоватьВладельца(док.ТМЦ);
				спрЕд.ВыбратьЭлементы();
				Пока спрЕд.ПолучитьЭлемент()>0 Цикл
					Если спрЕд.Ед=док.ТМЦ.БазЕдиница Тогда
						док.Ед = спрЕд.ТекущийЭлемент();
						док.Коэффициент = спрЕд.Коэффициент;
						Прервать;
					КонецЕсли;
				КонецЦикла;
				Если ПустоеЗначение(ЦенаПродажи) = 0 тогда
					док.ЦенаБезНДС = ЦенаПродажи;
				иначе
					Если док.Клиент.ТипЦен = Перечисление.ТипыЦен.Категория1 тогда 
						Если ЦенаПродажи = док.ТМЦ.Цена1 тогда
							док.ЦенаБезНДС = док.ТМЦ.Цена1;
						иначе
							док.ЦенаБезНДС = ЦенаПродажи;
						КонецЕсли;
					КонецЕсли;
					Если док.Клиент.ТипЦен = Перечисление.ТипыЦен.Категория2 тогда 
						Если ЦенаПродажи = док.ТМЦ.Цена2 тогда
							док.ЦенаБезНДС = док.ТМЦ.Цена2;
						иначе
							док.ЦенаБезНДС = ЦенаПродажи;
						КонецЕсли;
					КонецЕсли;
					Если док.Клиент.ТипЦен = Перечисление.ТипыЦен.Категория3 тогда
						Если ЦенаПродажи = док.ТМЦ.Цена3 тогда
							док.ЦенаБезНДС = док.ТМЦ.Цена3;
						иначе
							док.ЦенаБезНДС = ЦенаПродажи;
						КонецЕсли;
					КонецЕсли;
				КонецЕсли;
				док.СуммаБезНДС = Число(док.ЦенаБезНДС*док.Кво);
				док.СуммаБезСкидки = док.СуммаБезНДС; 
				док.СуммаСНДС= док.СуммаБезНДС;
				Если (док.ТМЦ.Вид = Перечисление.ВидыТМЦ.Товар) или (док.ТМЦ.Вид = Перечисление.ВидыТМЦ.Телефон)  тогда
					спрПартии = СоздатьОбъект("Справочник.Партии");
					спрПартии.ИспользоватьДату(РабочаяДата());
					спрПартии.ИспользоватьВладельца(док.ТМЦ);
					спрПартии.ВыбратьЭлементы();
					Пока спрПартии.ПолучитьЭлемент() = 1 Цикл
						Если (Регистр.Остатки.СводныйОстаток(0,док.ТМЦ,док.Склад,спрПартии.ТекущийЭлемент(),"Кво")>док.Кво) или (Регистр.Остатки.СводныйОстаток(0,док.ТМЦ,док.Склад,спрПартии.ТекущийЭлемент(),"Кво")=док.Кво) тогда
							док.Партия = спрПартии.ТекущийЭлемент();
							док.ЦенаЗакупки = спрПартии.Цена_Уч;
							док.СуммаЗакупки = Число(спрПартии.Цена_Уч*Количество); 
							Прервать;
						КонецЕсли;
					КонецЦикла; 
				иначе
					Спр = СоздатьОбъект("Справочник.Партии");
					Спр.ИспользоватьВладельца(док.ТМЦ);
					Если Спр.НайтиПоКоду(0)=0 Тогда  // всегда с нулевым кодом
						Спр.Новый();
						Спр.Код = 0;
						Спр.Владелец = док.ТМЦ;
						Спр.Наименование = "Партия по умолчанию";
						Спр.Записать();
					КонецЕсли;
					док.Партия = Спр.ТекущийЭлемент();
					док.ЦенаЗакупки = док.ТМЦ.Цена_Прих*док.Курс;
					док.СуммаЗакупки = Число(док.ЦенаЗакупки*Количество);
				КонецЕсли;	
			иначе
				Сообщить(" В справочнике товаров не обнаружен данный продукт: "+Код);
			КонецЕсли;
		КонецЕсли;
	КонецЦикла;
	док.Записать(); 
	ЗафиксироватьТранзакцию();
	КонтекстФормы2 = док.ТекущийДокумент();
	Константа.УстановитьАтрибут("НомерДокИнтернетМагазин",док.ТекущийДокумент());
	Сообщить("СозданнаНакладная "+док.ТекущийДокумент());
КонецПроцедуры

Процедура ВыгрузитьОстатки()
	УстановкаСоединения();
	ЗапросНоменклатура = СоздатьОбъект("Запрос");
	ТекстЗапроса = 	"//{{ЗАПРОС(ВыбратьНоменклатуру)
	|Номенклатура = Справочник.ДопРеквизиты.ТекущийЭлемент;
	|НоменклатураТМЦ = Справочник.ДопРеквизиты.ТМЦ.ТекущийЭлемент;
	|НоменклатураЦена = Справочник.ДопРеквизиты.ТМЦ.ТекущийЭлемент.Цена2;
	|Условие(Номенклатура.АйДи <> 0);
	|Условие(Номенклатура.Включить = Перечисление.ДаНет.Да);
	|Группировка Номенклатура;
	|Функция Сч = Счётчик();
	|";//}}ЗАПРОС
	Если ЗапросНоменклатура.Выполнить(ТекстЗапроса) = 0 Тогда
		Возврат;
	КонецЕсли;
	Кол = 0;
	Размер = ЗапросНоменклатура.Сч;
	Пока ЗапросНоменклатура.Группировка(1) = 1 Цикл
		Номенклатура = ЗапросНоменклатура.Номенклатура;
		НоменклатураТМЦ = ЗапросНоменклатура.НоменклатураТМЦ; 
		НоменклатураЦена = ЗапросНоменклатура.НоменклатураЦена;
		Если Номенклатура.ЭтоГруппа() = 0 тогда
			Кол = Кол+1;
			глПрогрессор("Выгружаю Остатки",Размер,Кол);
			Ид = СокрЛП(Номенклатура.АйДи);
			Остаток = Регистр.Остатки.СводныйОстаток(0,НоменклатураТМЦ,Константа.БазСклад,,"Кво");
			Запрос = "UPDATE `oc_product` SET `quantity` = "+Остаток+", `price`="+НоменклатураЦена+" WHERE `product_id` = "+Ид; 
			Соединение.Execute(Запрос);
		КонецЕсли;
	КонецЦикла;
КонецПроцедуры


Процедура УведомлениеТелеграмм()
	Если Параметр.РазмерСписка() > 0 тогда
		ОткрытьФорму("Обработка.Бот_Телеграм",Параметр);
	КонецЕсли;
КонецПроцедуры

Процедура ПриОткрытии()
	//ВыгрузитьОстатки();
	//Состояние("Получение и обработка данных с CaseRoom.in.ua");
	Параметр=СоздатьОбъект("СписокЗначений");
	Если ПустоеЗначение(Форма.Параметр) = 0 тогда
		Если Форма.Параметр = "1" тогда
			ВыгрузитьОстатки();
		иначе
			ДанныеДляДокумента = Форма.Параметр;
			СформироватьНакладную(ДанныеДляДокумента);
		КонецЕсли; 
		Форма.Закрыть();
	иначе
		ЗаказыПолучить();
		ЗаказыЗаписать();
		УведомлениеТелеграмм();	
		Форма.Закрыть();
	КонецЕсли;
КонецПроцедуры



