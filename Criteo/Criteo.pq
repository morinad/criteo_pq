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



Criteo.Func =( start as text, end as text)=>
let
data = Text.ToBinary("reportType=CampaignPerformance&startDate="&dateFunc(start)&"&endDate="&dateFunc(end)&"&dimensions=Day&dimensions=CampaignId&metrics=Displays&metrics=Clicks&metrics=AdvertiserCost&metrics=SalesPc&format=Csv&currency=RUB&timezone=GMT"),
headers = [#"Content-Type"="application/x-www-form-urlencoded", #"Accept"="application/octet-stream", #"Authorization"="Bearer "&tokenFunc(Extension.CurrentCredential()[Username],Extension.CurrentCredential()[Password])],
web = Web.Contents("https://api.criteo.com/", [RelativePath = "marketing/v1/statistics", Content = data, Headers = headers, ManualStatusHandling = {404, 400}]),
result = Csv.Document(web, null, ";"),
    #"Повышенные заголовки" = Table.PromoteHeaders(result, [PromoteAllScalars=true]),
#"Извлеченный текст после разделителя" = Table.TransformColumns(#"Повышенные заголовки", {{"Day", each Text.AfterDelimiter(_, " "), type text}}),
    #"Разделить столбец по разделителю" = Table.SplitColumn(#"Извлеченный текст после разделителя", "Day", Splitter.SplitTextByDelimiter("/", QuoteStyle.Csv), {"Day.1", "Day.2", "Day.3"}),
    #"Добавлен пользовательский объект" = Table.AddColumn(#"Разделить столбец по разделителю", "Date", each [Day.3]&"-"&[Day.1]&"-"&[Day.2]),
    #"Удаленные столбцы" = Table.RemoveColumns(#"Добавлен пользовательский объект",{"Day.1", "Day.2", "Day.3"}),
    #"Измененный тип" = Table.TransformColumnTypes( #"Удаленные столбцы" ,{{"Date", type date}, {"Impressions", Int64.Type}, {"Clicks", Int64.Type}, {"Sales", Int64.Type}}),
    #"Измененный тип с языком" = Table.TransformColumnTypes(#"Измененный тип", {{"Cost", type number}}, "en-AU")
in
    #"Измененный тип с языком";



dateFunc= (dat)=>
       if dat = "yesterday" then Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()) , -1),"yyyy-MM-dd") 
       else if dat = "today" then Date.ToText(Date.From(DateTime.LocalNow()),"yyyy-MM-dd")
       else if (try Number.From(Text.BeforeDelimiter(dat,"daysAgo")) otherwise 0) >0 then Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()),-1*Number.From(Text.BeforeDelimiter(dat,"daysAgo"))),"yyyy-MM-dd") 
       else dat;


tokenFunc=(log, pass)=> 
let
data = Text.ToBinary("client_id="&log&"&client_secret="&pass&"&grant_type=client_credentials"),
headers = [#"Content-Type"="application/x-www-form-urlencoded", #"Accept"="application/json"],
web = Web.Contents("https://api.criteo.com/", [RelativePath = "marketing/oauth2/token", Content = data, Headers = headers, ManualStatusHandling = {404, 400}]),
result = Json.Document(web)[access_token]
in result;




Criteo = [
    TestConnection = (dataSourcePath) => { "Criteo.Data", Json.Document(dataSourcePath)[start],Json.Document(dataSourcePath)[end]},
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
