unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, odbcconn, sqldb, FileUtil, Forms, Controls, Graphics,
  Dialogs, StdCtrls, DBGrids, ComCtrls, LibXmlComps, IdHTTP, laz2_DOM,
  laz2_XMLRead, laz2_XMLWrite, laz2_XMLCfg, laz2_XMLUtils, laz_XMLStreaming,
  RestRequest, IdAuthentication, IdMultipartFormData, IdURI, IdSSL,
  IdSSLOpenSSL, fpjson;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnFilter1: TButton;
    btnUpdate: TButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    DataSource4: TDataSource;
    dbAccess: TODBCConnection;
    edtDataFinal: TEdit;
    edtKey: TEdit;
    edtData: TEdit;
    edtDomain: TEdit;
    IdHTTP1: TIdHTTP;
    Key1: TLabel;
    Label1: TLabel;
    Key: TLabel;
    Label2: TLabel;
    lblStatus1: TLabel;
    lblStatus2: TLabel;
    lblStatus3: TLabel;
    lblStatus4: TLabel;
    lblStatus6: TLabel;
    lblStatus7: TLabel;
    lblStatus8: TLabel;
    SQLEstoqueSyncTudo: TSQLQuery;
    SQLFilial: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    procedure btnFilter1Click(Sender: TObject);
    procedure btnUpdateClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Label1Click(Sender: TObject);
    procedure lblTotalClick(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;
  selected: Integer;
  sync: Boolean;
  total, countSync: Integer; // Total products to be updated
  tfUpdate: TextFile;

const
  ESTOQUE_FILE_NAME = 'EstoquePreco.txt';
  GET_FILENAME = 'get.xml';

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Label1Click(Sender: TObject);
begin

end;

procedure TForm1.lblTotalClick(Sender: TObject);
begin

end;

procedure TForm1.btnUpdateClick(Sender: TObject);
var
  tfIn, tfOut3: TextFile;
  s, respStr, idStockAvailable : string;
  j, totalNew : Integer;
  httpClient : TIdHttp;
  Result, Result2 : THttpResponse;
  List1, ListCategories, ListImages, ListStock, ListCombinations, ListAux: TStringList;
  jData, jItem, jAssociations : TJSONData;
  jData2 : TJSONData;
  newProduct : Boolean;


  // Put Product method
  procedure Put_Product(xmlStrList: TStringList; xmlListCategories: TStringList; xmlListImages: TStringList; xmlListCombinations: TStringList);
  var
    httpClient: TIdHttp;
    Result: THttpResponse;
    respStr, xmlStr: string;
    XMLRequest: TStringStream;
    tfOut: TextFile;
    i : integer;
  begin
    //Código = xmlStrList[0], Descrição = xmlStrList[1], Estoque = xmlStrList[2], Preço = xmlStrList[3],
    //Peso = xmlStrList[4], LinkRewrite = xmlStrList[5], Reference = xmlStrList[6], ShowPrice = xmlStrList[7],
    //Active = xmlStrList[8], Width = xmlStrList[9], Height = xmlStrList[10], Depth = xmlStrList[11],
    //Description = xmlStrList[12], DescriptionShort = xmlStrList[13], available_for_order = xmlStrList[14],
    //id_manufacturer = xmlStrList[15], id_supplier = xmlStrList[16], id_category_default = xmlStrList[17],
    //cache_default_attribute = xmlStrList[18], id_default_image = xmlStrList[19], id_default_combination = xmlStrList[20],
    //id_tax_rules_group = xmlStrList[21], position_in_category = xmlStrList[22], manufacturer_name = xmlStrList[23]
    //quantity = xmlStrList[24], type = xmlStrList[25], id_shop_default = xmlStrList[26],
    //supplier_reference = xmlStrList[27], location = xmlStrList[28], quantity_discount = xmlStrList[29],
    //ean13 = xmlStrList[30], upc = xmlStrList[31], cache_is_pack = xmlStrList[32],
    //cache_has_attachments = xmlStrList[33], is_virtual = xmlStrList[34], on_sale = xmlStrList[35],
    //online_only = xmlStrList[36], ecotax = xmlStrList[37], minimal_quantity = xmlStrList[38],
    //wholesale_price = xmlStrList[39], unity = xmlStrList[40], unit_price_ratio = xmlStrList[41],
    //additional_shipping_cost = xmlStrList[42], customizable = xmlStrList[43], text_fields = xmlStrList[44],
    //redirect_type = xmlStrList[45], id_product_redirected = xmlStrList[46], available_date = xmlStrList[47],
    //condition = xmlStrList[48], indexed = xmlStrList[49], visibility = xmlStrList[50],
    //advanced_stock_management = xmlStrList[51], pack_stock_type = xmlStrList[52], meta_description = xmlStrList[53],
    //meta_keywords = xmlStrList[54], meta_title = xmlStrList[55], available_now = xmlStrList[56],
    //available_later = xmlStrList[57], uploadable_files = xmlStrList[58]

    xmlStr := '<prestashop xmlns:xlink="http://www.w3.org/1999/xlink">'+
	    '<product>'+
              '<id>'+xmlStrList[0]+'</id>'+
              '<id_manufacturer>'+xmlStrList[15]+'</id_manufacturer>'+
              '<id_supplier>'+xmlStrList[16]+'</id_supplier>'+
              '<id_category_default>'+xmlStrList[17]+'</id_category_default>'+
              '<cache_default_attribute>'+xmlStrList[18]+'</cache_default_attribute>'+
              '<id_default_image>'+xmlStrList[19]+'</id_default_image>'+
              '<id_default_combination>'+xmlStrList[20]+'</id_default_combination>'+
              '<id_tax_rules_group>0</id_tax_rules_group>'+
              '<position_in_category>'+xmlStrList[22]+'</position_in_category>'+
              //'<manufacturer_name>'+xmlStrList[23]+'</manufacturer_name>'+
              //'<quantity>'+xmlStrList[24]+'</quantity>'+
              '<type>'+xmlStrList[25]+'</type>'+
              '<id_shop_default>'+xmlStrList[26]+'</id_shop_default>'+
	      '<reference>'+xmlStrList[6]+'</reference>'+
              '<supplier_reference>'+xmlStrList[27]+'</supplier_reference>'+
              '<location>'+xmlStrList[28]+'</location>'+
  	      '<width>'+stringReplace(xmlStrList[9] , ',',  '.' ,[rfReplaceAll, rfIgnoreCase])+'</width>'+
	      '<height>'+stringReplace(xmlStrList[10] , ',',  '.' ,[rfReplaceAll, rfIgnoreCase])+'</height>'+
	      '<depth>'+stringReplace(xmlStrList[11] , ',',  '.' ,[rfReplaceAll, rfIgnoreCase])+'</depth>'+
	      '<weight>'+stringReplace(xmlStrList[4] , ',',  '.' ,[rfReplaceAll, rfIgnoreCase])+'</weight>'+
              '<quantity_discount>'+xmlStrList[29]+'</quantity_discount>'+
              '<ean13>'+xmlStrList[30]+'</ean13>'+
              '<upc>'+xmlStrList[31]+'</upc>'+
              '<cache_is_pack>'+xmlStrList[32]+'</cache_is_pack>'+
              '<cache_has_attachments>'+xmlStrList[33]+'</cache_has_attachments>'+
              '<is_virtual>'+xmlStrList[34]+'</is_virtual>'+
              '<on_sale>'+xmlStrList[35]+'</on_sale>'+
              '<online_only>'+xmlStrList[36]+'</online_only>'+
              '<ecotax>'+xmlStrList[37]+'</ecotax>'+
              '<minimal_quantity>'+xmlStrList[38]+'</minimal_quantity>'+
	      //'<price>'+stringreplace(Copy(xmlStrList[3],0, Pos(',', xmlStrList[3]) + 3), ',', '.', [rfReplaceAll, rfIgnoreCase])+'</price>'+
              '<price>'+xmlStrList[3]+'</price>'+
              '<wholesale_price>'+xmlStrList[39]+'</wholesale_price>'+
              '<unity>'+xmlStrList[40]+'</unity>'+
              '<unit_price_ratio>'+xmlStrList[41]+'</unit_price_ratio>'+
              '<additional_shipping_cost>'+xmlStrList[42]+'</additional_shipping_cost>'+
              '<customizable>'+xmlStrList[43]+'</customizable>'+
              '<text_fields>'+xmlStrList[44]+'</text_fields>'+
              '<uploadable_files>'+xmlStrList[58]+'</uploadable_files>'+
	      '<active>'+xmlStrList[8]+'</active>'+
              '<redirect_type>'+xmlStrList[45]+'</redirect_type>'+
              '<id_product_redirected>'+xmlStrList[46]+'</id_product_redirected>'+
              '<available_for_order>'+xmlStrList[14]+'</available_for_order>'+
              '<available_date>'+xmlStrList[47]+'</available_date>'+
              '<condition>'+xmlStrList[48]+'</condition>'+
              '<show_price>'+xmlStrList[7]+'</show_price>'+
              '<indexed>'+xmlStrList[49]+'</indexed>'+
              '<visibility>'+xmlStrList[50]+'</visibility>'+
              '<advanced_stock_management>'+xmlStrList[51]+'</advanced_stock_management>'+
              '<pack_stock_type>'+xmlStrList[52]+'</pack_stock_type>'+
              '<meta_description>'+xmlStrList[53]+'</meta_description>'+
              '<meta_keywords>'+xmlStrList[54]+'</meta_keywords>'+
              '<meta_title>'+xmlStrList[55]+'</meta_title>'+
	      '<link_rewrite><language>'+trim(xmlStrList[5])+'</language></link_rewrite>'+
	      '<name><language>'+xmlStrList[1]+'</language></name>'+
	      '<description><language>'+xmlStrList[12]+'</language></description>'+
	      '<description_short><language>'+xmlStrList[13]+'</language></description_short>'+
              '<available_now>'+xmlStrList[56]+'</available_now>'+
              '<available_later>'+xmlStrList[57]+'</available_later>'+
	      '<associations>'+
              '<categories>';

    for i := 0 to xmlListCategories.Count -1 do
    begin
         xmlStr := xmlStr+
                '<category>'+
	          '<id>'+xmlListCategories[i]+'</id>'+
	        '</category>';
    end;

    xmlStr := xmlStr+'</categories>'+
	        '<images>';

    for i := 0 to xmlListImages.Count -1 do
    begin
         xmlStr := xmlStr+
                '<image>'+
	          '<id>'+xmlListImages[i]+'</id>'+
	        '</image>';
    end;

    xmlStr := xmlStr+'</images>'+
              '<combinations>';

    for i := 0 to xmlListCombinations.Count -1 do
    begin
         xmlStr := xmlStr+
                '<combination>'+
	          '<id>'+xmlListCombinations[i]+'</id>'+
	        '</combination>';
    end;

    xmlStr := xmlStr+'</combinations>'+
	      '</associations>'+
	    '</product>'+
            '</prestashop>';

    //Write the XML to test
    AssignFile(tfOut, 'test.xml');
    rewrite(tfOut);
    writeln(tfOut, xmlStr);
    CloseFile(tfOut);

    AssignFile(tfOut, 'rewrite.txt');
    rewrite(tfOut);
    writeln(tfOut, xmlStrList[5]);
    CloseFile(tfOut);

    httpClient := TIdHttp.Create(nil);
    XMLRequest := TStringStream.Create(xmlStr);

    with httpClient do
    begin
         Request.CustomHeaders.Clear;
         ConnectTimeout := 5000;
         ReadTimeout := 100000;
         Request.Connection := 'Keep-Alive';
         Request.Accept := 'text/xml';
         Request.ContentType := 'text/xml';
         Request.ContentEncoding := 'utf-8';
    end;

    try
       respStr := httpClient.Put(edtDomain.text+'/api/products?ws_key='+edtKey.text, XMLRequest);
       Result.ResponseCode := httpClient.ResponseCode;
       Result.ResponseStr := respStr;

       if Result.ResponseCode = 200 then
       begin
          lblStatus4.Caption := 'Produto código '+xmlStrList[0]+' atualizado com sucesso!';
          lblStatus4.refresh;
       end
       else
       begin
          AssignFile(tfOut, 'Put_Product_'+xmlStrList[0]+'.txt');
          rewrite(tfOut);
          writeln(tfOut, 'Result.ResponseCode: '+inttostr(Result.ResponseCode));
          CloseFile(tfOut);
       end;
    except
        on E: EIdHTTPProtocolException do
        begin
          //showMessage(xmlStrList[0]);
          //showMessage('Price: '+stringreplace(Copy(xmlStrList[3],0, 4), '.', ',', [rfReplaceAll, rfIgnoreCase]));

          AssignFile(tfOut, 'exception.txt');
          append(tfOut);
          writeln(tfOut, 'Id: '+xmlStrList[0]);
          writeln(tfOut, 'Price: '+stringreplace(Copy(xmlStrList[3],0, 4), ',', '.', [rfReplaceAll, rfIgnoreCase]));
          writeln(tfOut, edtDomain.text+'/api/products?ws_key='+edtKey.text);
          writeln(tfOut, ' ======= ');
          writeln(tfOut, xmlStr);
          writeln(tfOut, ' ======= ');
          writeln(tfOut, '');

          CloseFile(tfOut);

          Result.ResponseCode := httpClient.ResponseCode;
          Result.ResponseStr := E.Message;
        end;
    end;

    httpClient.Free;
  end;

    // Put StockAvailables method
  procedure Put_StockAvailable(stockList: TStringList; quantity: String);
  var
    httpClient: TIdHttp;
    Result: THttpResponse;
    respStr, xmlStock: string;
    XMLRequest: TStringStream;
    tfOut2: TextFile;
  begin

    // id = stockList[0], idProduct = stockList[1], id_product_attribute = stockList[2]
    // id_shop = stockList[3], id_shop_group = stockList[4], depends_on_stock = stockList[5]
    // out_of_stock = stockList[6]

    xmlStock := '<prestashop xmlns:xlink="http://www.w3.org/1999/xlink">'+
	    '<stock_available>'+
              '<id>'+stockList[0]+'</id>'+
              '<id_product>'+stockList[1]+'</id_product>'+
              '<id_product_attribute>'+stockList[2]+'</id_product_attribute>'+
              '<id_shop>'+stockList[3]+'</id_shop>'+
              '<id_shop_group>'+stockList[4]+'</id_shop_group>'+
              '<quantity>'+quantity+'</quantity>'+
              '<depends_on_stock>'+stockList[5]+'</depends_on_stock>'+
              '<out_of_stock>'+stockList[6]+'</out_of_stock>'+
	    '</stock_available>'+
            '</prestashop>';

    //Write the XML to test
    AssignFile(tfOut2, 'test_stock.xml');
    rewrite(tfOut2);
    writeln(tfOut2, xmlStock);
    CloseFile(tfOut2);

    httpClient := TIdHttp.Create(nil);
    XMLRequest := TStringStream.Create(xmlStock);

    with httpClient do
    begin
         Request.CustomHeaders.Clear;
         ConnectTimeout := 5000;
         ReadTimeout := 100000;
         Request.Connection := 'Keep-Alive';
         Request.Accept := 'text/xml';
         Request.ContentType := 'text/xml';
         Request.ContentEncoding := 'utf-8';
    end;

    try
       respStr := httpClient.Put(edtDomain.text+'/api/stock_availables?ws_key='+edtKey.text, XMLRequest);
       Result.ResponseCode := httpClient.ResponseCode;
       Result.ResponseStr := respStr;

       if Result.ResponseCode = 200 then
       begin
          lblStatus8.Caption := 'ESTOQUE do produto '+stockList[1]+' atualizado com sucesso!';
          lblStatus8.refresh;
       end
       else
       begin
            AssignFile(tfOut2, 'Put_Stock_'+inttostr(Result.ResponseCode)+'.txt');
            rewrite(tfOut2);
            writeln(tfOut2, 'Result.ResponseCode: '+inttostr(Result.ResponseCode));
            CloseFile(tfOut2);
       end;
    except
        on E: EIdHTTPProtocolException do
        begin
          AssignFile(tfOut2, 'Put_Product_'+inttostr(httpClient.ResponseCode)+'.txt');
          rewrite(tfOut2);
          writeln(tfOut2, edtDomain.text+'/api/stock_availables?ws_key='+edtKey.text);
          writeln(tfOut2, E.Message);
          CloseFile(tfOut2);

          Result.ResponseCode := httpClient.ResponseCode;
          Result.ResponseStr := E.Message;
        end;
    end;

    httpClient.Free;
  end;
begin
     // List to get Cod, Price and Quantity from the txt file (txt file got data from the access db)
     List1 := TStringList.Create;
     List1.StrictDelimiter := true;
     List1.Delimiter := ';';

     btnUpdate.Enabled := false;

     //Just create the TXT file to be used in Put methods
     AssignFile(tfIn, 'exception.txt');
     rewrite(tfIn);
     writeln(tfIn, 'Exceptions:');
     CloseFile(tfIn);

     //Open the ESTOQUE file, got data from Access db
     AssignFile(tfIn, ESTOQUE_FILE_NAME);

     if total = 0 then
     begin
          ListAux := TStringlist.Create;
          ListAux.LoadFromFile(ESTOQUE_FILE_NAME);
          total := ListAux.Count;
     end;

     try
        reset(tfIn);
        countSync := 0;
        totalNew := 0;

        while not eof(tfIn) do
        begin
          //Create the http object
          httpClient := TIdHttp.Create(nil);
          with httpClient do
          begin
               Request.CustomHeaders.Clear;
               ConnectTimeout := 5000;
               ReadTimeout := 100000;
               Request.Connection := 'Keep-Alive';
               Request.ContentEncoding := 'utf-8';
          end;

          readln(tfIn, s);
          List1.DelimitedText := s;
          ListStock := TStringList.Create;
          countSync := countSync+1;
          newProduct := false; //Tells if the product is new

          try
             //Update label status (counting)
             lblStatus3.Caption := 'Atualizando registro '+inttostr(countSync)+' de '+inttostr(total);
             lblStatus3.refresh;

             // === GET product info to update
             lblStatus6.Caption := 'Buscando dados do produto no site...';
             lblStatus6.refresh;
             respStr := httpClient.Get(edtDomain.text+'/api/products/'+List1[0]+'?output_format=JSON&ws_key='+edtKey.text);
             Result.ResponseCode := httpClient.ResponseCode;

             Result.ResponseStr := respStr;
             lblStatus6.Caption := 'Já temos os dados do produto.';
             lblStatus6.refresh;

             if Result.ResponseCode <> 200 then
                ShowMessage('Ocorreu um erro na captura dos dados, favor avisar o administrador');

             // === Read the Json file to update
             jData := GetJSON(Result.ResponseStr);

          except
              on E: EIdHTTPProtocolException do
              begin
                Result.ResponseCode := httpClient.ResponseCode;
                Result.ResponseStr := E.Message;

                if Result.ResponseCode = 404 then
                begin
                     //Add new register
                     totalNew := totalNew+1;
                     lblStatus7.Caption := inttostr(totalNew)+' novos produtos';
                     lblStatus7.Refresh;
                     newProduct := true;
                end;

              end;
          end;

          if newProduct = false then
          begin
            try
               idStockAvailable := '';

               // Get stock_availables id
               jAssociations := jData.Items[0].FindPath('associations');
               jItem := jAssociations.FindPath('stock_availables');
               idStockAvailable := jItem.Items[0].FindPath('id').AsString;

               // === GET product stock info
               lblStatus4.Caption := 'Buscando ESTOQUE do produto no site...';
               lblStatus4.refresh;
               respStr := httpClient.Get(edtDomain.text+'/api/stock_availables/'+idStockAvailable+'?output_format=JSON&ws_key='+edtKey.text);
               Result2.ResponseCode := httpClient.ResponseCode;

               Result2.ResponseStr := respStr;
               lblStatus4.Caption := 'Já temos os dados de ESTOQUE do produto.';
               lblStatus4.refresh;

               if Result2.ResponseCode <> 200 then
                  ShowMessage('Ocorreu um erro na captura dos dados de ESTOQUE, favor avisar o administrador');

               // === Read the Json file to update
               jData2 := GetJSON(Result2.ResponseStr);
            except
                on E: EIdHTTPProtocolException do
                begin
                  AssignFile(tfOut3, 'Get_Stock_'+inttostr(httpClient.ResponseCode)+'.txt');
                  rewrite(tfOut3);
                  writeln(tfOut3, 'Result.ResponseCode: '+inttostr(httpClient.ResponseCode));
                  writeln(tfOut3, edtDomain.text+'/api/stock_availables/'+idStockAvailable+'?output_format=JSON&ws_key='+edtKey.text);
                  CloseFile(tfOut3);

                  Result2.ResponseCode := httpClient.ResponseCode;
                  Result2.ResponseStr := E.Message;
                end;
            end;
          end;

          httpClient.Free;

          if newProduct = false then
          begin
            // Uses the Json info
            //Memo2.Lines.Add(jData.Items[0].FindPath('link_rewrite').AsString);

            // === Complete the List1 with all required fields
            List1.add(jData.Items[0].FindPath('link_rewrite').AsString);
            List1.add(jData.Items[0].FindPath('reference').AsString);
            List1.add(jData.Items[0].FindPath('show_price').AsString);
            List1.add(jData.Items[0].FindPath('active').AsString);
            List1.add(jData.Items[0].FindPath('width').AsString);
            List1.add(jData.Items[0].FindPath('height').AsString);
            List1.add(jData.Items[0].FindPath('depth').AsString);
            List1.add(jData.Items[0].FindPath('description').AsString);
            List1.add(jData.Items[0].FindPath('description_short').AsString);
            List1.add(jData.Items[0].FindPath('available_for_order').AsString);
            List1.add(jData.Items[0].FindPath('id_manufacturer').AsString);
            List1.add(jData.Items[0].FindPath('id_supplier').AsString);
            List1.add(jData.Items[0].FindPath('id_category_default').AsString);
            List1.add(jData.Items[0].FindPath('cache_default_attribute').AsString);
            List1.add(jData.Items[0].FindPath('id_default_image').AsString);
            List1.add(jData.Items[0].FindPath('id_default_combination').AsString);
            List1.add(jData.Items[0].FindPath('id_tax_rules_group').AsString);
            List1.add(jData.Items[0].FindPath('position_in_category').AsString);
            List1.add(jData.Items[0].FindPath('manufacturer_name').AsString);
            List1.add(jData.Items[0].FindPath('quantity').AsString);
            List1.add(jData.Items[0].FindPath('type').AsString);
            List1.add(jData.Items[0].FindPath('id_shop_default').AsString);
            List1.add(jData.Items[0].FindPath('supplier_reference').AsString);
            List1.add(jData.Items[0].FindPath('location').AsString);
            List1.add(jData.Items[0].FindPath('quantity_discount').AsString);
            List1.add(jData.Items[0].FindPath('ean13').AsString);
            List1.add(jData.Items[0].FindPath('upc').AsString);
            List1.add(jData.Items[0].FindPath('cache_is_pack').AsString);
            List1.add(jData.Items[0].FindPath('cache_has_attachments').AsString);
            List1.add(jData.Items[0].FindPath('is_virtual').AsString);
            List1.add(jData.Items[0].FindPath('on_sale').AsString);
            List1.add(jData.Items[0].FindPath('online_only').AsString);
            List1.add(jData.Items[0].FindPath('ecotax').AsString);
            List1.add(jData.Items[0].FindPath('minimal_quantity').AsString);
            List1.add(jData.Items[0].FindPath('wholesale_price').AsString);
            List1.add(jData.Items[0].FindPath('unity').AsString);
            List1.add(jData.Items[0].FindPath('unit_price_ratio').AsString);
            List1.add(jData.Items[0].FindPath('additional_shipping_cost').AsString);
            List1.add(jData.Items[0].FindPath('customizable').AsString);
            List1.add(jData.Items[0].FindPath('text_fields').AsString);
            List1.add(jData.Items[0].FindPath('redirect_type').AsString);
            List1.add(jData.Items[0].FindPath('id_product_redirected').AsString);
            List1.add(jData.Items[0].FindPath('available_date').AsString);
            List1.add(jData.Items[0].FindPath('condition').AsString);
            List1.add(jData.Items[0].FindPath('indexed').AsString);
            List1.add(jData.Items[0].FindPath('visibility').AsString);
            List1.add(jData.Items[0].FindPath('advanced_stock_management').AsString);
            List1.add(jData.Items[0].FindPath('pack_stock_type').AsString);
            List1.add(jData.Items[0].FindPath('meta_description').AsString);
            List1.add(jData.Items[0].FindPath('meta_keywords').AsString);
            List1.add(jData.Items[0].FindPath('meta_title').AsString);
            List1.add(jData.Items[0].FindPath('available_now').AsString);
            List1.add(jData.Items[0].FindPath('available_later').AsString);
            List1.add(jData.Items[0].FindPath('uploadable_files').AsString);
            //List1.add(jData.Items[0].FindPath('new').AsString);

            //List of all StockAvailable information (the 1st Stock Available)
            ListStock.add(jData2.Items[0].FindPath('id').AsString);
            ListStock.add(jData2.Items[0].FindPath('id_product').AsString);
            ListStock.add(jData2.Items[0].FindPath('id_product_attribute').AsString);
            ListStock.add(jData2.Items[0].FindPath('id_shop').AsString);
            ListStock.add(jData2.Items[0].FindPath('id_shop_group').AsString);
            ListStock.add(jData2.Items[0].FindPath('depends_on_stock').AsString);
            ListStock.add(jData2.Items[0].FindPath('out_of_stock').AsString);

            // Get all associations -> categories, images and ...
            jAssociations := jData.Items[0].FindPath('associations');

            // Get all categories
            jItem := jAssociations.FindPath('categories');
            ListCategories := TStringList.Create;
            for j := 0 to jItem.Count - 1 do
            begin
              //Memo2.Lines.Add(jItem.Items[j].FindPath('id').AsString);
              ListCategories.add(jItem.Items[j].FindPath('id').AsString);
            end;

            // Get all images
            jItem := jAssociations.FindPath('images');
            ListImages := TStringList.Create;
            for j := 0 to jItem.Count - 1 do
            begin
              //Memo2.Lines.Add(jItem.Items[j].FindPath('id').AsString);
              ListImages.add(jItem.Items[j].FindPath('id').AsString);
            end;

            // Get all combinations
            jItem := jAssociations.FindPath('combinations');
            ListCombinations := TStringList.Create;
            if jItem <> nil then
              for j := 0 to jItem.Count - 1 do
              begin
                //Memo2.Lines.Add(jItem.Items[j].FindPath('id').AsString);
                ListCombinations.add(jItem.Items[j].FindPath('id').AsString);
              end;

            Put_Product(List1, ListCategories, ListImages, ListCombinations);
            Put_StockAvailable(ListStock, List1[2]);
          end;

        end;
        CloseFile(tfIn);

        ShowMessage('Atualização da loja virtual finalizada com sucesso!');

     except
        on E: EInOutError do
        begin
          AssignFile(tfOut3, 'OpenFile_Estoque_'+inttostr(httpClient.ResponseCode)+'.txt');
          rewrite(tfOut3);
          writeln(tfOut3, 'Result.ResponseCode: '+inttostr(httpClient.ResponseCode));
          CloseFile(tfOut3);
        end;
     end;

     btnUpdate.Enabled:=true;
end;

procedure TForm1.btnFilter1Click(Sender: TObject);
var
  cod_es: Integer;
  med_fil: Extended;
  estoque_atual: Extended;
  situacao_e, preco_venda_formatted, estoque_atual_formatted: String;
  F, Variant: TextFile;
  sync: Boolean;

  qant_es, en_ant_es, ed_ant_es: Extended;
  sd_ant_es, pr_ant_es, an_ant_es: Extended;
  peso_es, preco_venda: Extended;
begin
     if (edtData.text = '') then
     begin
          ShowMessage('Favor informar as duas datas');
          exit;
     end;

     if (edtDataFinal.text = '') then
     begin
          ShowMessage('Favor informar as duas datas');
          exit;
     end;

     lblStatus1.caption := 'Abrindo conexão com banco ESTOQUE';
     lblStatus1.refresh;

     try
        dbAccess.Connected := true;

        with SQLEstoqueSyncTudo do
         begin
            close;
            sql.text := 'select Count(*)-1 as Total from ESTOQUE WHERE alter_es >= :Date and alter_es <= :DateF';
            ParamByName('Date').AsDateTime := StrToDate(edtData.Text);
            ParamByName('DateF').AsDateTime := StrToDate(edtDataFinal.Text);
            open;

            total := strtoint(SQLEstoqueSyncTudo['total']);

            close;
            sql.text := 'SELECT * FROM estoque WHERE alter_es >= :Date and alter_es <= :DateF order by alter_es asc';
            ParamByName('Date').AsDateTime := StrToDate(edtData.Text);
            ParamByName('DateF').AsDateTime := StrToDate(edtDataFinal.Text);
            open;
            first;

            lblStatus2.caption := 'Criando arquivo com '+inttostr(total)+' registros atualizados';
            lblStatus2.refresh;

            // Open TXT File
            AssignFile(F, ESTOQUE_FILE_NAME);
            Rewrite(F);

            While not (SQLEstoqueSyncTudo.Eof) do
            begin
              cod_es := SQLEstoqueSyncTudo['cod_es'];

              // Get 'med_fil' field from ESTFILIAL table
              with SQLFilial do
              begin
                  close;
                  sql.text := 'SELECT * from estfilial WHERE prod_fil = :Codigo';
                  ParamByName('Codigo').AsInteger := cod_es;
                  open;

                  med_fil := 0;
                  if SQLFilial['med_fil'] <> null then
                     med_fil := SQLFilial['med_fil'];

                  close;
              end;

              qant_es := 0;
              if SQLEstoqueSyncTudo['qant_es'] <> null then
                 qant_es := SQLEstoqueSyncTudo['qant_es'];

              en_ant_es := 0;
              if SQLEstoqueSyncTudo['en_ant_es'] <> null then
                 en_ant_es := SQLEstoqueSyncTudo['en_ant_es'];

              ed_ant_es := 0;
              if SQLEstoqueSyncTudo['ed_ant_es'] <> null then
                 ed_ant_es := SQLEstoqueSyncTudo['ed_ant_es'];

              sd_ant_es := 0;
              if SQLEstoqueSyncTudo['sd_ant_es'] <> null then
                 sd_ant_es := SQLEstoqueSyncTudo['sd_ant_es'];

              pr_ant_es := 0;
              if SQLEstoqueSyncTudo['pr_ant_es'] <> null then
                 pr_ant_es := SQLEstoqueSyncTudo['pr_ant_es'];

              an_ant_es := 0;
              if SQLEstoqueSyncTudo['an_ant_es'] <> null then
                 an_ant_es := SQLEstoqueSyncTudo['an_ant_es'];

              estoque_atual := qant_es + en_ant_es + ed_ant_es - sd_ant_es - pr_ant_es - an_ant_es + med_fil;
              estoque_atual_formatted := stringreplace(Copy(floattostr(estoque_atual),0, Pos(',', floattostr(estoque_atual)) + 1), ',', '.', [rfReplaceAll, rfIgnoreCase]);

              preco_venda := 0;
              if SQLEstoqueSyncTudo['vlrcom1_es'] <> null then
              begin
                 preco_venda := SQLEstoqueSyncTudo['vlrcom1_es'];

                 // Without round
                 //preco_venda_formatted := stringreplace(Copy(floattostr(preco_venda),0, Pos(',', floattostr(preco_venda)) + 2), ',', '.', [rfReplaceAll, rfIgnoreCase]);

                 // With round
                 preco_venda_formatted := formatfloat('#.##', preco_venda);
                 preco_venda_formatted := stringreplace(preco_venda_formatted, ',', '.', [rfReplaceAll, rfIgnoreCase]);
              end;

              peso_es := 0;
              if SQLEstoqueSyncTudo['peso_es'] <> null then
                 peso_es := SQLEstoqueSyncTudo['peso_es'];

              situacao_e := '0';
              if SQLEstoqueSyncTudo['situacao_e'] <> null then
                 situacao_e := SQLEstoqueSyncTudo['situacao_e'];

              sync := true;
              if situacao_e <> null then
              begin
                   if (situacao_e = '4') OR (situacao_e = '5') then
                      sync := false;
              end;

              if (sync = true) AND (preco_venda > 0) then
                   WriteLn(F, inttostr(cod_es)+';'+SQLEstoqueSyncTudo['desc_es']+';'+estoque_atual_formatted+';'+preco_venda_formatted+';'+floattostr(peso_es));

              SQLEstoqueSyncTudo.Next;
            end;
            lblStatus1.caption := 'Fechando conexão com banco ESTOQUE';
            lblStatus1.refresh;

            close;
            dbAccess.Connected := false;

            CloseFile(F);

            lblStatus2.caption := 'Arquivo criado com '+inttostr(total)+' registros atualizados.';
            lblStatus2.refresh;
         end;

        btnUpdate.Enabled := true;

        ShowMessage('Importação dos produtos alterados finalizada com sucesso!');

     except
      on E: EODBCException do
      begin
        ShowMessage('Não foi possível conectar com o banco de dados.');
        lblStatus1.caption := 'Não foi possível conectar com o banco de dados.';
        lblStatus1.refresh;
      end;

      on E: EVariantError do
      begin
        ShowMessage('Erro de Variant, veja o arquivo erro_variant.txt');
        AssignFile(Variant, 'erro_variant.txt');
        Rewrite(Variant);
        WriteLn(Variant, 'desc: '+SQLEstoqueSyncTudo['desc_es']);
        WriteLn(Variant, 'cod_es: '+inttostr(cod_es)+', Estoque: '+floattostr(estoque_atual)+', vlrcom1_es: '+floattostr(preco_venda)+', peso_es: '+floattostr(peso_es));
        WriteLn(Variant, 'qant_es: '+floattostr(qant_es)+', en_ant_es: '+floattostr(en_ant_es)+', ed_ant_es: '+floattostr(ed_ant_es)+', sd_ant_es: '+floattostr(sd_ant_es)+', pr_ant_es: '+floattostr(pr_ant_es)+', an_ant_es: '+floattostr(an_ant_es)+', med_fil: '+floattostr(med_fil));
        CloseFile(Variant);
      end;
     end;
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
     edtData.text := FormatDateTime('dd/mm/yyyy', now - 1);
     edtDataFinal.text := FormatDateTime('dd/mm/yyyy', now - 1);
end;


end.

