// This file contains your Data Connector logic
section Criteo;

[DataSource.Kind="Criteo", Publish="Criteo.Publish"]
shared Criteo.Data = Value.ReplaceType(Criteo.Func, FuncType);

FuncType = type function (
    
    start as (type text meta [
        Documentation.FieldCaption = "Start date:",
        Documentation.FieldDescription = "Enter the first date of your statistics. You can specify date in YYYY-MM-DD format or use dynamic formats: today, yesterday, 69daysAgo.",
        Documentation.SampleValues = {"2020-02-28"}
    ]),
     end as (type text meta [
        Documentation.FieldCaption = "End date:",
        Documentation.FieldDescription = "Enter the last date of your statistics. You can specify date in YYYY-MM-DD format or use dynamic formats: today, yesterday, 69daysAgo.",
        Documentation.SampleValues = {"yesterday"}
    ]),
    advertiserId as (type nullable text meta [
        Documentation.FieldCaption = "ID клиента:",
        Documentation.SampleValues = {"12345"}
    ])

    )
    as table meta [
        Documentation.Name = "Criteo.Data Function",
        Documentation.LongDescription = "Created to get data from Criteo service",
        Documentation.Examples = {
        [
            Description = "Returns table from Criteo",
            Code = "Criteo.Data(""2020-02-20"",""yesterday"")",
            Result = "Table from Criteo by days and campaigns."
        ],
        [
            Description = "Returns table from Criteo",
            Code = "Criteo.Data(""69daysAgo"",""today"")",
            Result = "Table from Criteo by days and campaigns."
        ]
        }
    ];



Criteo.Func =(start as text, end as text, advertiserId as nullable text)=>
let
data=if advertiserId <> null then 
"{'advertiserIds': '" & advertiserId &"', 'startDate': '" &dateFunc(start)& "', 'endDate': '"& dateFunc(end) &"', 'dimensions': ['Day','CampaignId'], 'metrics': ['Displays','AdvertiserCost','Clicks'], 'format': 'csv', 'currency': 'RUB', 'timezone': 'GMT'}" else 
"{'startDate': '" &dateFunc(start)& "', 'endDate': '"& dateFunc(end) &"', 'dimensions': ['Day','CampaignId'], 'metrics': ['Displays','AdvertiserCost','Clicks'], 'format': 'csv', 'currency': 'RUB', 'timezone': 'GMT'}" ,

headers = [#"Content-Type"="application/json", #"Accept"="application/octet-stream",  #"Authorization"="Bearer "&tokenFunc(Extension.CurrentCredential()[Username],Extension.CurrentCredential()[Password])],
web = Web.Contents("https://api.criteo.com/2021-07/statistics/report", [ Content = Text.ToBinary(data), Headers = headers, ManualStatusHandling = {404,415, 400}]),
result = Csv.Document(web, null, ";"),
    #"Повышенные заголовки" = Table.PromoteHeaders(result, [PromoteAllScalars=true]),
    #"Измененный тип" = Table.TransformColumnTypes(   #"Повышенные заголовки"  ,{{"Day", type date}, {"Displays", Int64.Type}, {"Clicks", Int64.Type}}),
    lang = Table.TransformColumnTypes(#"Измененный тип", {{"AdvertiserCost", type number}}, "en-AU"),

 ren1 = try Table.RenameColumns(lang ,{{"Day", "Дата"}}) otherwise lang ,
    ren2 = try Table.RenameColumns(ren1 ,{{"AdvertiserCost", "Расход"}}) otherwise ren1 ,
    ren3 = try Table.RenameColumns(ren2 ,{{"Clicks", "Клики"}}) otherwise ren2 ,
    ren4 = try Table.RenameColumns(ren3 ,{{"Displays", "Показы"}}) otherwise ren3 ,
    ren5 = try Table.RenameColumns(ren4 ,{{"Currency", "Валюта"}}) otherwise ren4 ,
    ren6 = try Table.RenameColumns(ren5 ,{{"Campaign", "Кампания"}}) otherwise ren5, 
    ren7 = try Table.RenameColumns(ren6 ,{{"CampaignId", "ID кампании"}}) otherwise ren6 ,
    ren8 = try Table.RenameColumns(ren7 ,{{"CampaignType", "Тип кампании"}}) otherwise ren7 ,
    ren9 = try Table.RenameColumns(ren8 ,{{"Sales", "Продажи"}}) otherwise ren8,
    ren10 = try Table.RenameColumns(ren9 ,{{"Advertiser Name", "Клиент"}}) otherwise ren9 

in
   ren10 ;



dateFunc= (dat)=>
       if dat = "yesterday" then Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()) , -1),"yyyy-MM-dd") 
       else if dat = "today" then Date.ToText(Date.From(DateTime.LocalNow()),"yyyy-MM-dd")
       else if (try Number.From(Text.BeforeDelimiter(dat,"daysAgo")) otherwise 0) >0 then Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()),-1*Number.From(Text.BeforeDelimiter(dat,"daysAgo"))),"yyyy-MM-dd") 
       else dat;


tokenFunc=(log, pass)=> 
let
data = Text.ToBinary("client_id="&log&"&client_secret="&pass&"&grant_type=client_credentials"),
headers = [#"Content-Type"="application/x-www-form-urlencoded", #"Accept"="application/json"],
web = Web.Contents("https://api.criteo.com/oauth2/token", [ Content = data, Headers = headers, ManualStatusHandling = {404, 400}]),
result = Json.Document(web)[access_token]
in result;




Criteo = [
    TestConnection = (dataSourcePath) => { "Criteo.Data", Json.Document(dataSourcePath)[start],Json.Document(dataSourcePath)[end],Json.Document(dataSourcePath)[advertiserId]?},
    Authentication = [
        
         UsernamePassword  = []
   
    ],
    Label = "Criteo Connection"
];



Criteo.Publish = [
    Beta = false,
    Category = "Other",
    ButtonText = { "Criteo Connector", "Criteo Help" },
    LearnMoreUrl = "https://www.youtube.com/channel/UCqSLNYLN_3mf6nA1Xf7fu1g/",
    SourceImage = Criteo.Icons,
    SourceTypeImage = Criteo.Icons
];



Criteo.Icons = [
    Icon16 = { Extension.Contents("Criteo16.png"), Extension.Contents("Criteo20.png"), Extension.Contents("Criteo24.png"), Extension.Contents("Criteo32.png") },
    Icon32 = { Extension.Contents("Criteo32.png"), Extension.Contents("Criteo40.png"), Extension.Contents("Criteo48.png"), Extension.Contents("Criteo64.png") }
];
