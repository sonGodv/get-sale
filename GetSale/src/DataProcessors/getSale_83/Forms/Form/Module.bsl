//  Обработка получает заказы с сайта, создаёт новый заказ в справочнике и 
//  формирует расходные накладные на основе полученных данных.
//
//

Var ADOBDConnection, 
	Connected,
	ServerDB,
	Encoding,
	Base,
	Driver,
	Login,
	Password,
	OrdersTable,
	ProductTable, 
	SelectedCustomers,
	ServiceParameters Export;

// 
//   Читает настройки из файла конфигурации. Записавает данные в глобальные переменные
//
//

Procedure DownloadSettings()
	
	//ФС1 = СоздатьОбъект("ФС");
	PathToFile = InfoBaseConnectionString() + "settings.inf";
	ConfigurationFile = New File(PathToFile);
		
	If ConfigurationFile.Exist() Then
			
		ConfigurationFile.Read(PathToFile);
		
		Driver     = TrimAll(ConfigurationFile.GetLine(1)); //  "MySQL ODBC 5.3 Unicode Driver"
		ServerDB   = TrimAll(ConfigurationFile.GetLine(2));  //  "109.94.209.16"
		Base       = TrimAll(ConfigurationFile.GetLine(3));    //  "caseroom_db"
		Login      = TrimAll(ConfigurationFile.GetLine(4));   //  "caseroom_db"
		Password   = TrimAll(ConfigurationFile.GetLine(5));   //  "мой_пасс"
		
		If ConfigurationFile.GetLine(6) = "1" Then
			Encoding = 1;
		EndIf;
		
		If TrimAll(ConfigurationFile.GetLine(7)) = "1" Then
			SalesInvoice = 1;
		EndIf;
		
		// Клиент по умолчанию используемый для формирования накладных
	
		If TrimAll(ConfigurationFile.GetLine(8)) <> "0" Then
			Customer = Catalogs.Customers.FindByCode(TrimAll(ConfigurationFile.GetLine(8)));
			If Customer <> Undefined Then
				SelectedCustomers = Customer;
			Else
				SelectedCustomers = " ";
			EndIf;
		EndIf;
			
		// Основной Склад 
		If TrimAll(ConfigurationFile.GetLine(9)) <> "0" Then
			Warehouse = Catalogs.Warehouses.FindByCode(TrimAll(ConfigurationFile.GetLine(9)));
			If Warehouse <> Undefined Then
				SelectedWarehouse = Warehouse;
			Else
				SelectedWarehouse = " ";
			EndIf;
		EndIf;           
			If TrimAll(ConfigurationFile.GetLine(10)) <> "0" Then
			Firm = Catalogs.Firms.FindByCode(TrimAll(ConfigurationFile.GetLine(10)));
			If Firm <> Undefined Then
				SelectedFirm = Firm;
			Else
				SelectedFirm = " ";
			EndIf;
		EndIf;             
		
//		morelocale 		= TrimAll(ConfigurationFile.GetLine(11)); 	
//		ОснЛокаль 		= TrimAll(ConfigurationFile.GetLine(12));  		
//		ДопЛокаль 		= TrimAll(ConfigurationFile.GetLine(13)); 	
//		Кей 			= TrimAll(ConfigurationFile.GetLine(14));        		
//		АйдиЯзык 		= TrimAll(ConfigurationFile.GetLine(15));
//		Прокси 			= TrimAll(ConfigurationFile.GetLine(16)); 
//		пСервер 		= TrimAll(ConfigurationFile.GetLine(17));
//		пПорт 			= TrimAll(ConfigurationFile.GetLine(18));
//		ФтпСервер 		= TrimAll(ConfigurationFile.GetLine(19));
//		ФтпЛогин 		= TrimAll(ConfigurationFile.GetLine(20));
//		ФтпПароль 		= TrimAll(ConfigurationFile.GetLine(21));
//		КаталогФтп 		= TrimAll(ConfigurationFile.GetLine(22));
//		КаталогФтпФото 	= TrimAll(ConfigurationFile.GetLine(23));
		
	EndIf;
	
EndProcedure

//
// Устанавливает соединения с базой сайта.
//
//

Procedure SetUpConnection()
	
	DownloadSettings();
		
	ADOBDConnection = New COMObject("ADODB.Connection");
	
	If Encoding = 1 Then
		StringEncoding = "STMT=set character_set_results=cp1251;"
	Else
		StringEncoding = "";
	EndIf;
	
	ConnectionString = "DRIVER=" + TrimAll(Driver) + ";SERVER="
						+ TrimAll(ServerDB)+";DataBase="+TrimAll(Base)
						+ ";UID="+TrimAll(Login)+";PWD="+TrimAll(Password)
						+ ";"+TrimAll(StringEncoding);
			
	Try
		ADOBDConnection.Open(ConnectionString);
		Connected = 1;
	Except
		Connected = 0;
		Message = New UserMessage();
		Message.Text = "Can't connect to database!";
		Message.Message();
	EndTry;
	
EndProcedure

//
//  Получает заказы из базы MySQL используя MySQL Connector
//  и записывает в OrdersTable (ТаблицаЗначений, глобальная область видимости)
//

Procedure GetOrders()
	
	SetUpConnection();
	
	Order = ADOBDConnection.Execute(
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
	
	OrdersTable = New ValueTable;
	OrdersTable.Columns.Add("order_id",,"order_id",);
	OrdersTable.Columns.Add("customer_id",,"customer_id",);
	OrdersTable.Columns.Add("firstname",,"Имя",);
	OrdersTable.Columns.Add("lastname",,"Фамилия",);
	OrdersTable.Columns.Add("email",,"email",);
	OrdersTable.Columns.Add("telephone",,"telephone",);
	OrdersTable.Columns.Add("payment_method",,"Метод оплаты",);
	OrdersTable.Columns.Add("payment_code",,"Код оплаты",);
	OrdersTable.Columns.Add("shipping_method",,"Метод отправки",);
	OrdersTable.Columns.Add("shipping_firstname",,"Имя получателя",);	
	OrdersTable.Columns.Add("shipping_lastname",,"Фамилия получателя",);
	OrdersTable.Columns.Add("shipping_address_1",,"Адрес доставки",);
	OrdersTable.Columns.Add("shipping_city",,"Город",);
	OrdersTable.Columns.Add("shipping_postcode",,"Индекс/Отделение",);	
	OrdersTable.Columns.Add("shipping_zone",,"Область",);	
	OrdersTable.Columns.Add("shipping_code",,"Метод доставки",);	
	OrdersTable.Columns.Add("comment",,"Комментарий",);
	OrdersTable.Columns.Add("total",,"Сумма",);
	OrdersTable.Columns.Add("order_status_id",,"Статус заказа",);
	OrdersTable.Columns.Add("ip",,"ip Пользователя",);	
	OrdersTable.Columns.Add("po_date_added",,"Дата заказа",);	
	
	ProductTable = New ValueTable;
	ProductTable.Columns.Add("order_id",,"order_id",);
	ProductTable.Columns.Add("product_id",,"product_id",);
	ProductTable.Columns.Add("sku",,"sku",);
	ProductTable.Columns.Add("name",,"name",); 
	ProductTable.Columns.Add("quantity",,"quantity",); 
	ProductTable.Columns.Add("price",,"price",); 
	ProductTable.Columns.Add("total",,"total",); 
	
	//StringNumber = 0;
	
	NumberLinesProducts = 0;
	
	While Order.Eof() = 0 Do
				
		//StringNumber = StringNumber + 1;
		
		NewStringOrderTable = OrdersTable.Add();
		//NewStringOrderTable.StringNumber = НомСтрок;
		FillPropertyValues(NewStringOrderTable, Order.Fields);
		
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"order_id",Order.Fields.Item("order_id").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"customer_id",Order.Fields.Item("customer_id").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"firstname",Order.Fields.Item("firstname").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"lastname",Order.Fields.Item("lastname").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"email",Order.Fields.Item("email").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"telephone",Order.Fields.Item("telephone").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"payment_method",Order.Fields.Item("payment_method").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"payment_code",Order.Fields.Item("payment_code").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"total",Order.Fields.Item("total").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"shipping_method",Order.Fields.Item("shipping_method").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"shipping_code",Order.Fields.Item("shipping_code").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"shipping_firstname",Order.Fields.Item("shipping_firstname").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"shipping_lastname",Order.Fields.Item("shipping_lastname").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"shipping_address_1",Order.Fields.Item("shipping_address_1").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"shipping_city",Order.Fields.Item("shipping_city").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"shipping_postcode",Order.Fields.Item("shipping_postcode").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"shipping_zone",Order.Fields.Item("shipping_zone").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"comment",Order.Fields.Item("comment").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"order_status_id",Order.Fields.Item("order_status_id").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"ip",Order.Fields.Item("ip").value);
		//ТабЗаказов.УстановитьЗначение(НомСтрок,"po_date_added",Order.Fields.Item("date_added").value);
		
		
		Products = ADOBDConnection.Execute(
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
		|WHERE `order_id` ="+Order.Fields.Item("order_id").value+" 
		|ORDER BY `order_id`  DESC"
		);
		While Products.Eof() = 0 Do
			NumberLinesProducts = NumberLinesProducts + 1;
			NewStringProductTable = ProductTable.Add();
			FillPropertyValues(NewStringProductTable, Products.Fields)
//			ProductTable.УстановитьЗначение(NumberLinesProducts,"order_id",Товар.Fields.Item("order_id").value);
//			ProductTable.УстановитьЗначение(NumberLinesProducts,"sku",Товар.Fields.Item("sku").value);
//			ProductTable.УстановитьЗначение(NumberLinesProducts,"product_id",Товар.Fields.Item("product_id").value);
//			ProductTable.УстановитьЗначение(NumberLinesProducts,"name",Товар.Fields.Item("name").value); 
//			ProductTable.УстановитьЗначение(NumberLinesProducts,"quantity",Товар.Fields.Item("quantity").value);
//			ProductTable.УстановитьЗначение(NumberLinesProducts,"price",Товар.Fields.Item("price").value);
//			ProductTable.УстановитьЗначение(NumberLinesProducts,"total",Товар.Fields.Item("total").value);
			Products.MoveNext();
		EndDo;
		Order.MoveNext();
	EndDo;
EndProcedure  

//
//
// Создаёт элементы в справочнике "Задачи"(Изначально создавал для создания текущих задач)
// OrdersTable - ТаблицаЗначений с глобальной областью видимости. Заполняется в процедуре GetOrders()  
//
//

Procedure RecordOrders()
	
	//ОСТАНОВИЛСЯ ТУТ
	
	спрЗаказы=СоздатьОбъект("Справочник.Задачи");
	
	спрСтат = СоздатьОбъект("Справочник.СтатусЗаказа");
	
	спрСтр = СоздатьОбъект("Справочник.Сотрудники");
	спрЗаказы.ИспользоватьДату(РабочаяДата());
	НомСтрок = 0;
	Для ы=1 по OrdersTable.КоличествоСтрок() Do
		If спрЗаказы.НайтиПоРеквизиту("id",OrdersTable.ПолучитьЗначение(ы,"order_id"),1) = 0 Then
			Тел = TrimAll(OrdersTable.ПолучитьЗначение(ы,"telephone"));
			спрЗаказы.Новый();
			спрЗаказы.id = OrdersTable.ПолучитьЗначение(ы,"order_id");
			спрЗаказы.Наименование = OrdersTable.ПолучитьЗначение(ы,"lastname")+" "+OrdersTable.ПолучитьЗначение(ы,"firstname"); 
			спрЗаказы.Фамилия = OrdersTable.ПолучитьЗначение(ы,"lastname"); 
			спрЗаказы.Телефон = Прав(Тел,10); 
			спрЗаказы.эмаил = OrdersTable.ПолучитьЗначение(ы,"email"); 
			спрЗаказы.зДата = OrdersTable.ПолучитьЗначение(ы,"po_date_added"); 
			If спрСтр.FindByCode("5",0) = 1 Then
				спрЗаказы.Менеджер = спрСтр.ТекущийЭлемент();
			EndIf;
			If спрСтат.НайтиПоРеквизиту("АйДи",OrdersTable.ПолучитьЗначение(ы,"order_status_id"),1) = 1 Then
				спрЗаказы.СтатусЗаказа = спрСтат.ТекущийЭлемент();
			EndIf;
			If TrimAll(OrdersTable.ПолучитьЗначение(ы,"payment_code")) = "privat" Then
				спрЗаказы.МетодОплаты = Перечисления.ВидыТорговли.ПереводНаКарту;
			EndIf;
			If TrimAll(OrdersTable.ПолучитьЗначение(ы,"payment_code")) = "cod" Then
				спрЗаказы.МетодОплаты = Перечисления.ВидыТорговли.Наложка;
			EndIf;
			If TrimAll(OrdersTable.ПолучитьЗначение(ы,"payment_code")) = "wayforpay" Then
				спрЗаказы.МетодОплаты = Перечисления.ВидыТорговли.WayForPay;
			EndIf;
			If TrimAll(OrdersTable.ПолучитьЗначение(ы,"shipping_code")) = "novaposhta.novaposhta" Then
				нп=1;
				спрЗаказы.МетодДоствки = Перечисления.ВидДоставки.НоваяПочта;
			EndIf;
			If TrimAll(OrdersTable.ПолучитьЗначение(ы,"shipping_code")) = "avtolux.avtolux" Then
				спрЗаказы.МетодДоствки = Перечисления.ВидДоставки.УкрПочта;
			EndIf;
			If TrimAll(OrdersTable.ПолучитьЗначение(ы,"shipping_code")) = "pickup.pickup" Then
				спрЗаказы.МетодДоствки = Перечисления.ВидДоставки.Самовывоз;
			EndIf;
			спрЗаказы.Область = OrdersTable.ПолучитьЗначение(ы,"shipping_city");// OrdersTable.ПолучитьЗначение(ы,"shipping_zone");
			спрЗаказы.Город = OrdersTable.ПолучитьЗначение(ы,"shipping_city");
			спрЗаказы.ИндексОтдел = OrdersTable.ПолучитьЗначение(ы,"shipping_postcode");
			If нп =1 Then 
				РефГород = OrdersTable.ПолучитьЗначение(ы,"shipping_address_1");
				Город = Лев(РефГород,Найти(РефГород,";")-1);
				Отделение = Сред(РефГород,Найти(РефГород,";")+1);
				спрЗаказы.РефОбл = Город;
				спрЗаказы.РефОтделения = Отделение; 
		
				спрЗаказы.Адрес = TrimAll(OrdersTable.ПолучитьЗначение(ы,"shipping_city"))+", "+TrimAll(OrdersTable.ПолучитьЗначение(ы,"shipping_postcode")); 
			Else
				спрЗаказы.Адрес = OrdersTable.ПолучитьЗначение(ы,"shipping_address_1");
			EndIf;
			спрЗаказы.Статус = Перечисления.ДаНет.Нет;
			//спрЗаказы.Адрес = OrdersTable.ПолучитьЗначение(ы,"shipping_address_1");
			спрЗаказы.ТелефонПол = спрЗаказы.Телефон;
			спрЗаказы.Плательщик = Перечисления.Плательщик.Recipient;
			спрЗаказы.Сумма = Формат(OrdersTable.ПолучитьЗначение(ы,"total"),"Ч12.2");
			спрКл = СоздатьОбъект("Справочник.Clients");
			спрКл.ИспользоватьДату(РабочаяДата());
			If (спрКл.НайтиПоРеквизиту("Email",OrdersTable.ПолучитьЗначение(ы,"email"),1) = 1) или (спрКл.НайтиПоРеквизиту("Телефоны",OrdersTable.ПолучитьЗначение(ы,"telephone"),1) = 1)  Then
				спрЗаказы.зКлиент = спрКл.ТекущийЭлемент();
			Else
				Родитель = SelectedCustomers.Родитель;
				спрКл.ИспользоватьРодителя(Родитель);
				спрКл.Новый();
				спрКл.Код_ = Строка(OrdersTable.ПолучитьЗначение(ы,"customer_id"));
				спрКл.Наименование = Строка(OrdersTable.ПолучитьЗначение(ы,"firstname")+" "+OrdersTable.ПолучитьЗначение(ы,"lastname")); 
				спрКл.ПолнНаименование = спрКл.Наименование;
				спрКл.Адрес = Строка(OrdersTable.ПолучитьЗначение(ы,"shipping_zone"))+" "+Строка(OrdersTable.ПолучитьЗначение(ы,"shipping_city"))+" "+Строка(OrdersTable.ПолучитьЗначение(ы,"shipping_address_1")); 
				спрКл.ФизАдрес = спрКл.Адрес;
				спрКл.Телефоны = OrdersTable.ПолучитьЗначение(ы,"telephone");
				спрКл.ВалютаВзаиморасчетов = Константы.Гривня;
				спрКл.TradeType = Перечисления.ВидыТорговли.Предоплата;
				спрКл.ВозСкидка = Перечисления.ВариантыСкидок.БезСкидки;
				спрКл.ЗапрВыдачи = Перечисления.ДаНет.Нет; 
				спрКл.ТипЦен = Перечисления.PriceTypes.Category2;
				спрКл.Email = OrdersTable.ПолучитьЗначение(ы,"email");
				спрКл.Записать();
				спрЗаказы.зКлиент = спрКл.ТекущийЭлемент();
			EndIf;
			спрЗаказы.зДата = OrdersTable.ПолучитьЗначение(ы,"po_date_added");  
			спрЗаказы.Описание = OrdersTable.ПолучитьЗначение(ы,"comment");
			//++++++++++++++++++++++++++++++++++++++++  Список проданных товаров сворачиваю в строку и записываю в реквизит, который имеет тип - строка
			If ProductTable.КоличествоСтрок() <> 0 Then
				ProductTable.ВыбратьСтроки();
				_Строка = СоздатьОбъект("СписокЗначений");
				пр2 = 0;
				Для а = 1 По ProductTable.КоличествоСтрок() Do
					пр1 = TrimAll(ProductTable.ПолучитьЗначение(а,"order_id")); 
					пр2 = TrimAll(спрЗаказы.id);
					If пр1 = пр2 Then
						_Значение = "sku#"+Строка(TrimAll(ProductTable.ПолучитьЗначение(а,"sku")));
						_Строка.ДобавитьЗначение(_Значение);
						_Значение = "pid#"+Строка(TrimAll(ProductTable.ПолучитьЗначение(а,"product_id")));
						_Строка.ДобавитьЗначение(_Значение);
						_Значение = "nam#"+Строка(TrimAll(ProductTable.ПолучитьЗначение(а,"name")));
						_Строка.ДобавитьЗначение(_Значение);
						_Значение = "qua#"+Строка(TrimAll(ProductTable.ПолучитьЗначение(а,"quantity")));
						_Строка.ДобавитьЗначение(_Значение);
						_Значение = "pri#"+Строка(TrimAll(ProductTable.ПолучитьЗначение(а,"price")));
						_Строка.ДобавитьЗначение(_Значение);                                     
					EndIf;
				EndDo;
				спрЗаказы.Товар = _Строка.ВСтрокуСРазделителями(); 
			EndIf;
			//++++++++++++++++++++++++++++++++++++++++
			спрЗаказы.Записать();
			Message(Шаблон("Новый заказ: [спрЗаказы.id] Имя: [спрЗаказы.Наименование] [спрЗаказы.Фамилия] сумма: [Формат(OrdersTable.ПолучитьЗначение(ы,""total""),""Ч12.2"")]"));
			ServiceParameters.ДобавитьЗначение("Новый заказ: "+спрЗаказы.id);
			ServiceParameters.ДобавитьЗначение("ФИО: "+спрЗаказы.Фамилия+" "+спрЗаказы.Наименование);
			ServiceParameters.ДобавитьЗначение("Телефон: "+спрКл.Телефоны);
			ServiceParameters.ДобавитьЗначение("Сумма: "+Формат(OrdersTable.ПолучитьЗначение(ы,"total"),"Ч12.2"));
			ServiceParameters.ДобавитьЗначение("----------------------------");
		EndIf;
	EndDo;
EndProcedure

// Формимует документ "РасходнаяНакладная" на основе данных полученных с сайта
//
// var ДанныеДляДокумента - Таблица значений 
// 	Колонка("sku",,30,," ",2,,);
//  Колонка("quan",,,,,5,,);
//	Колонка("price",,,,"Наименование",35,,);
//  
//
Procedure СформироватьНакладную(ДанныеДляДокумента)
	КонтекстФормы2 = "";
	спрСтр = СоздатьОбъект("Справочник.Сотрудники");
	_Клиент = ДанныеДляДокумента.ПолучитьЗначение(1,"sku");
	Заказ = ДанныеДляДокумента.ПолучитьЗначение(2,"sku"); 
	КодМенеджер = ДанныеДляДокумента.ПолучитьЗначение(1,"price");  
	спрКлиент = СоздатьОбъект("Справочник.Clients");
	спрКлиент.ИспользоватьДату(РабочаяДата());
	If спрКлиент.FindByCode(_Клиент,0) = 1 Then
		Клиент = спрКлиент.ТекущийЭлемент();
	EndIf;
	НачатьТранзакцию();
	док = СоздатьОбъект("Документ.РасходнаяНакладная"); 
	спрТов = СоздатьОбъект("Справочник.ТМЦ");
	спрТов.ИспользоватьДату(РабочаяДата());
	док.Новый();
	//	If ПустоеЗначение(ДанныеДляДокумента.ПолучитьЗначение(2,"дата")) = 1 Then
	док.ДатаДок=РабочаяДата(); 
	//	Else
	//		док.ДатаДок = ДанныеДляДокумента.ПолучитьЗначение(2,"дата")
	//	EndIf;
	//	док.НомерДок = Лев(ИмяПользователя(),1)+"_"+док.НомерДок; 
	//    Message(док.НомерДок);
	док.Клиент = Клиент;
	док.Валюта = док.Клиент.ВалютаВзаиморасчетов;
	If Клиент.CounterpartyType = Перечисления.CounterpartyType.TT Then
		спрСклад = СоздатьОбъект("Справочник.Warehouses");
		If спрСклад.НайтиПоНаименованию(Клиент.Наименование,0,1) = 1 Then
			док.Склад = спрСклад.ТекущийЭлемент();
		EndIf;
	Else
		док.Склад = Константы.БазСклад;
	EndIf;
	
	док.AccountingType = Перечисления.ВидыУчета.Совместный;
	If спрСтр.FindByCode(TrimAll(КодМенеджер),0) = 1 Then
		док.Менеджер = спрСтр.ТекущийЭлемент();
	EndIf;
	//док.Менеджер = док.Клиент.Менеджер;
	док.ВидНДС = Константы.БазНДС.Получить(РабочаяДата()); 
	док.TradeType = док.Клиент.TradeType;
	док.ТипЦен = док.Клиент.ТипЦен;
	док.Курс = КурсДляВалюты(док.Валюта,док.ДатаДок);
	док.СчетПокупателя = СчетПоКоду("62.2");
	док.Фирма = Константы.БазФирма.Получить(ТекущаяДата());
	док.Отпустил = Константы.БазОтпустил;
	док.СубконтоВалДох = Константы.БазВалДоход;
	док.Основание = Строка("Создан на основании заказа "+Заказ);
	НомСтрок = 0;
	НомСтрокДок = 0;
	Для ы = 1 По ДанныеДляДокумента.КоличествоСтрок() Do
		НомСтрокДок = НомСтрокДок+1;
		Код = TrimAll(ДанныеДляДокумента.ПолучитьЗначение(НомСтрокДок,"sku")); 
		Количество = TrimAll(ДанныеДляДокумента.ПолучитьЗначение(НомСтрокДок,"quan"));  
		ЦенаПродажи = TrimAll(ДанныеДляДокумента.ПолучитьЗначение(НомСтрокДок,"price"));  
		If НомСтрокДок > 2 Then
			sku = TrimAll(Код);
			//Состояние(Шаблон("Обработка строки [НомСтрокДок] поиск: [sku]"));
			If спрТов.FindByCode(sku,0) = 1 Then
				НомСтрок = НомСтрок+1;
				док.НоваяСтрока();
				док.КодТов = спрТов.КодТов;
				док.ШтрихКод = спрТов.ШтрихКод;
				док.ТМЦ = спрТов.ТекущийЭлемент();
				док.Кво = Количество;
				спрЕд = СоздатьОбъект("Справочник.ЕдИзм");
				спрЕд.ИспользоватьВладельца(док.ТМЦ);
				спрЕд.ВыбратьЭлементы();
				While спрЕд.ПолучитьЭлемент()>0 Do
					If спрЕд.Ед=док.ТМЦ.БазЕдиница Then
						док.Ед = спрЕд.ТекущийЭлемент();
						док.Коэффициент = спрЕд.Коэффициент;
						Прервать;
					EndIf;
				EndDo;
				If ПустоеЗначение(ЦенаПродажи) = 0 Then
					док.ЦенаБезНДС = ЦенаПродажи;
				Else
					If док.Клиент.ТипЦен = Перечисления.PriceTypes.Category1 Then 
						If ЦенаПродажи = док.ТМЦ.Цена1 Then
							док.ЦенаБезНДС = док.ТМЦ.Цена1;
						Else
							док.ЦенаБезНДС = ЦенаПродажи;
						EndIf;
					EndIf;
					If док.Клиент.ТипЦен = Перечисления.PriceTypes.Category2 Then 
						If ЦенаПродажи = док.ТМЦ.Цена2 Then
							док.ЦенаБезНДС = док.ТМЦ.Цена2;
						Else
							док.ЦенаБезНДС = ЦенаПродажи;
						EndIf;
					EndIf;
					If док.Клиент.ТипЦен = Перечисления.PriceTypes.Category3 Then
						If ЦенаПродажи = док.ТМЦ.Цена3 Then
							док.ЦенаБезНДС = док.ТМЦ.Цена3;
						Else
							док.ЦенаБезНДС = ЦенаПродажи;
						EndIf;
					EndIf;
				EndIf;
				док.СуммаБезНДС = Число(док.ЦенаБезНДС*док.Кво);
				док.СуммаБезСкидки = док.СуммаБезНДС; 
				док.СуммаСНДС= док.СуммаБезНДС;
				If (док.ТМЦ.Вид = Перечисления.TypesOfInventory.Товар) или (док.ТМЦ.Вид = Перечисления.TypesOfInventory.Телефон)  Then
					спрПартии = СоздатьОбъект("Справочник.Партии");
					спрПартии.ИспользоватьДату(РабочаяДата());
					спрПартии.ИспользоватьВладельца(док.ТМЦ);
					спрПартии.ВыбратьЭлементы();
					While спрПартии.ПолучитьЭлемент() = 1 Do
						If (РегистрыНакопления.Remains.СводныйОстаток(0,док.ТМЦ,док.Склад,спрПартии.ТекущийЭлемент(),"Кво")>док.Кво) или (РегистрыНакопления.Remains.СводныйОстаток(0,док.ТМЦ,док.Склад,спрПартии.ТекущийЭлемент(),"Кво")=док.Кво) Then
							док.Партия = спрПартии.ТекущийЭлемент();
							док.ЦенаЗакупки = спрПартии.Цена_Уч;
							док.СуммаЗакупки = Число(спрПартии.Цена_Уч*Количество); 
							Прервать;
						EndIf;
					EndDo; 
				Else
					Спр = СоздатьОбъект("Справочник.Партии");
					Спр.ИспользоватьВладельца(док.ТМЦ);
					If Спр.FindByCode(0)=0 Then  // всегда с нулевым кодом
						Спр.Новый();
						Спр.Код = 0;
						Спр.Владелец = док.ТМЦ;
						Спр.Наименование = "Партия по умолчанию";
						Спр.Записать();
					EndIf;
					док.Партия = Спр.ТекущийЭлемент();
					док.ЦенаЗакупки = док.ТМЦ.Цена_Прих*док.Курс;
					док.СуммаЗакупки = Число(док.ЦенаЗакупки*Количество);
				EndIf;	
			Else
				Message(" В справочнике товаров не обнаружен данный продукт: "+Код);
			EndIf;
		EndIf;
	EndDo;
	док.Записать(); 
	ЗафиксироватьТранзакцию();
	КонтекстФормы2 = док.ТекущийДокумент();
	Константы.УстановитьАтрибут("НомерДокИнтернетМагазин",док.ТекущийДокумент());
	Message("СозданнаНакладная "+док.ТекущийДокумент());
EndProcedure

Procedure ВыгрузитьОстатки()
	SetUpConnection();
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
	If ЗапросНоменклатура.Выполнить(ТекстЗапроса) = 0 Then
		Возврат;
	EndIf;
	Кол = 0;
	Размер = ЗапросНоменклатура.Сч;
	While ЗапросНоменклатура.Группировка(1) = 1 Do
		Номенклатура = ЗапросНоменклатура.Номенклатура;
		НоменклатураТМЦ = ЗапросНоменклатура.НоменклатураТМЦ; 
		НоменклатураЦена = ЗапросНоменклатура.НоменклатураЦена;
		If Номенклатура.ЭтоГруппа() = 0 Then
			Кол = Кол+1;
			глПрогрессор("Выгружаю Остатки",Размер,Кол);
			Ид = TrimAll(Номенклатура.АйДи);
			Остаток = РегистрыНакопления.Remains.СводныйОстаток(0,НоменклатураТМЦ,Константы.БазСклад,,"Кво");
			Запрос = "UPDATE `oc_product` SET `quantity` = "+Остаток+", `price`="+НоменклатураЦена+" WHERE `product_id` = "+Ид; 
			ADOBDConnection.Execute(Запрос);
		EndIf;
	EndDo;
EndProcedure


Procedure УведомлениеТелеграмм()
	If ServiceParameters.РазмерСписка() > 0 Then
		ОткрытьФорму("Обработка.Бот_Телеграм",ServiceParameters);
	EndIf;
EndProcedure

Procedure ПриОткрытии()
	//ВыгрузитьОстатки();
	//Состояние("Получение и обработка данных с CaseRoom.in.ua");
	ServiceParameters=СоздатьОбъект("СписокЗначений");
	If ПустоеЗначение(ЭтаФорма.Parameters) = 0 Then
		If ЭтаФорма.ServiceParameters = "1" Then
			ВыгрузитьОстатки();
		Else
			ДанныеДляДокумента = ЭтаФорма.ServiceParameters;
			СформироватьНакладную(ДанныеДляДокумента);
		EndIf; 
		ЭтаФорма.Закрыть();
	Else
		GetOrders();
		RecordOrders();
		УведомлениеТелеграмм();	
		ЭтаФорма.Закрыть();
	EndIf;
EndProcedure

Функция КаталогИБ()
	СтрокаСоединенияСБД = СтрокаСоединенияИнформационнойБазы();
	ПозицияПоиска = Найти(Врег(СтрокаСоединенияСБД), "FILE=");
	If ПозицияПоиска = 1 Then
		// Файловая 
		Возврат Сред(СтрокаСоединенияСБД, 6,СтрДлина(СтрокаСоединенияСБД)-6);
		Else 
		// Серверная - Используем КаталогВременныхФайлов() 
		Возврат КаталогВременныхФайлов();
	EndIf;
КонецФункции
