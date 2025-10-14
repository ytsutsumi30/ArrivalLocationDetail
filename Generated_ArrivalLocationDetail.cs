//<ref>Newtonsoft.Json.dll</ref>
using System;
using Mongoose.IDO.Protocol;
using Mongoose.Scripting;
using Mongoose.Core.Common;
using Mongoose.Core.DataAccess;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Web;
using Newtonsoft.Json;

namespace Mongoose.FormScripts
{
   public class ArrivalLocationDetail : FormScript
   {
      /// <summary>
      /// グローバル変数
      /// </summary>
      string gIDOName = "ue_ADV_SLCoitems";        // ターゲットIDO名
      string gSSO = "1";        // SSOの使用、基本は1　1：はい　0：いいえ
      string gServerId = "0";        // APIサーバのID、詳しくはAPIサーバ関連
      string gSuiteContext = "CSI";        // APIスイートのコンテキスト、同上
      string gContentType = "application/json";        // 返り値のタイプ、基本設定不要もしくは"application/json"
      string gTimeout = "10000";        // タイムアウト設定
      string gSiteName = "Q72Q74BY8XUT3SKY_TRN_AJP";        // ターゲットIDOが存在するサイト名

      /// <summary>
      /// 取得データ、更新データ作成のクラス
      /// </summary>
      public class cItem
      {
         // 品目コード
         [JsonProperty("Item")]
         public string Item { get; set; }

         // 品目説明
         [JsonProperty("Description")]
         public string Description { get; set; }

         // 注文数量
         [JsonProperty("QtyOrderedConv")]
         public string QtyOrderedConv { get; set; }

         // 出荷済数量
         [JsonProperty("QtyShipped")]
         public string QtyShipped { get; set; }

         // オーダー番号
         [JsonProperty("CoNum")]
         public string CoNum { get; set; }

         // 更新日時
         [JsonProperty("ue_Uf_update_time_from_mongoose")]
         public string ue_Uf_update_time_from_mongoose { get; set; }

         // 更新者
         [JsonProperty("ue_Uf_updator_from_mongoose")]
         public string ue_Uf_updator_from_mongoose { get; set; }

         // オーダー明細行
         [JsonProperty("CoLine")]
         public string CoLine { get; set; }

         // リリース番号
         [JsonProperty("CoRelease")]
         public string CoRelease { get; set; }

         // レコード日付
         [JsonProperty("RecordDate")]
         public string RecordDate { get; set; }

         // 行ポインタ
         [JsonProperty("RowPointer")]
         public string RowPointer { get; set; }

         // アイテムID
         [JsonProperty("_ItemId")]
         public string _ItemId { get; set; }

      }

      /// <summary>
      /// web対応JSON整形用クラス
      /// </summary>
      public class WebJSONObject
      {
         // 納入場所
         [JsonProperty("DeliveryLocation")]
         public string DeliveryLocation { get; set; }

         // 出荷予定日
         [JsonProperty("ShipDate")]
         public string ShipDate { get; set; }

         // 出荷場所（倉庫）
         [JsonProperty("ShipLocation")]
         public string ShipLocation { get; set; }

         // 納入状況
         [JsonProperty("DeliveryStatus")]
         public string DeliveryStatus { get; set; }

         // 品目リスト
         [JsonProperty("Items")]
         public List<cItem> Items { get; set; }

      }

      /// <summary>
      /// APIを呼び出してデータ取得・グリッド表示を行う
      /// </summary>
      /// <param name="mode">操作モード（0:取得, 1:挿入, 2:更新, 4:削除）</param>
      public void callAPI(int mode){

         List<Property> propertiesList = new List<Property>();

         //使用するプロパティのデータリストを作成
         if(mode == 0){
            propertiesList.Add(new Property { Name = "Item", Value = "", Modified = true });
            propertiesList.Add(new Property { Name = "Description", Value = "", Modified = true });
            propertiesList.Add(new Property { Name = "QtyOrderedConv", Value = "", Modified = true });
            propertiesList.Add(new Property { Name = "QtyShipped", Value = "", Modified = true });
            propertiesList.Add(new Property { Name = "CoNum", Value = "", Modified = false });
            propertiesList.Add(new Property { Name = "ue_Uf_update_time_from_mongoose", Value = "", Modified = true });
            propertiesList.Add(new Property { Name = "ue_Uf_updator_from_mongoose", Value = "", Modified = true });
            propertiesList.Add(new Property { Name = "RecordDate", Value = "", Modified = true });
            propertiesList.Add(new Property { Name = "RowPointer", Value = "", Modified = true });
            propertiesList.Add(new Property { Name = "_ItemId", Value = "", Modified = true });
            propertiesList.Add(new Property { Name = "CoLine", Value = "", Modified = false });
            propertiesList.Add(new Property { Name = "CoRelease", Value = "", Modified = false });

         }
         //データ更新用、get時不要
         else{
            // 時間設定
            TimeZoneInfo jstZone = TimeZoneInfo.FindSystemTimeZoneById("Tokyo Standard Time");
            DateTime utcNow = DateTime.UtcNow;
            DateTime jstNow = TimeZoneInfo.ConvertTimeFromUtc(utcNow, jstZone);

            propertiesList.Add(new Property { Name = "ue_Uf_update_time_from_mongoose", Value = jstNow.ToString(), Modified = true });
            propertiesList.Add(new Property { Name = "ue_Uf_updator_from_mongoose", Value = ThisForm.Variables("User").Value, Modified = true });
            propertiesList.Add(new Property { Name = "CoNum", Value = ThisForm.Variables("selectCoNum").Value, Modified = false });
            propertiesList.Add(new Property { Name = "CoLine", Value = ThisForm.Variables("selectCoLine").Value, Modified = false });
            propertiesList.Add(new Property { Name = "CoRelease", Value = ThisForm.Variables("selectCoRelease").Value, Modified = false });
            //データ特定用、insert時は不要
            if(mode != 1){
               propertiesList.Add(new Property { Name = "RecordDate", Value = ThisForm.Variables("selectRecordDate").Value, Modified = true });
            //データ特定用、insert時は不要
            if(mode != 1){
               propertiesList.Add(new Property { Name = "RowPointer", Value = ThisForm.Variables("selectRowPointer").Value, Modified = true });
            //データ特定用、insert時は不要
            if(mode != 1){
               propertiesList.Add(new Property { Name = "_ItemId", Value = ThisForm.Variables("selectItemId").Value, Modified = true });
            }        
         }

         //データを取得
         string JSONResponse = getData(mode,gIDOName,propertiesList);
         // webに移行、grid更新する必要がなくなった
         if(mode != 0)return;

         //取得した結果はJSONなので、bodyを処理しデータを取得
         List<cItem> itemsList = JsonConvert.DeserializeObject<getJSONObject>(JSONResponse).Items;

         //処理結果を変数に格納
         ThisForm.Variables("vJSONResult").Value = GenerateWebSetJson(itemsList);
      }

      /// <summary>
      /// フィルター文字列を自動生成する
      /// </summary>
      /// <returns>フィルター文字列</returns>  
      private string GenerateFilter(){
         string header = "&filter=";
         string filter = "";

         // 検索欄から変数を獲得
         // CoNum
         if(ThisForm.Variables("gCoNum").Value != ""){
            // 接続詞追加
            if(filter != ""){filter += " and ";}
            // 検索値追加
            filter += $"CoNum=\'{ThisForm.Variables("gCoNum").Value}\'";
         }
         // Stat
         if(ThisForm.Variables("gStat").Value != ""){
            // 接続詞追加
            if(filter != ""){filter += " and ";}
            // 検索値追加
            filter += $"Stat=\'{ThisForm.Variables("gStat").Value}\'";
         }

         // 作成したフィルターを返す
         if (filter == ""){
            return "";
         }
         else
         {
            return header + filter;
         }
      }

      /// <summary>
      /// 画面遷移時の変数設定
      /// </summary>
      public void setParameterFormRun(){
         // グリッドの値を変数に持たせる
         // 将来の拡張用にプレースホルダーとして残します
      }

      /// <summary>
      /// web用データをJSON文字列を生成
      /// </summary>
      /// <param name="resultList">整形結果リスト</param>
      /// <returns>web用JSON文字列</returns>
      private string GenerateWebSetJson(List<cItem> resultList){
         // オブジェクトを作成
         var responseObject = new WebJSONObject
         {
            DeliveryLocation = ThisForm.Variables("gAdr0Name").Value ,
            ShipDate = ThisForm.Variables("gProjectedDate").Value ,
            ShipLocation = ThisForm.Variables("gWhse").Value ,
            DeliveryStatus = ThisForm.Variables("gStat").Value ,
            Items = resultList
         };

         // Formatting.Indented で整形して出力
         string jsonString = JsonConvert.SerializeObject(responseObject, Formatting.Indented);

         return jsonString;
      }

      
      //API取得JSONリスト化用クラス

      /// <summary>
      /// JSONからデータ取得用のクラス
      /// </summary>
      public class getJSONObject
      {
         [JsonProperty("Items")]
         public List<cItem> Items { get; set; }

      }

      /// <summary>
      /// 一番内側の Properties 配列の要素を表すクラス
      /// </summary>
      public class Property
      {
         [JsonProperty("Modified")]
         public bool Modified { get; set; }

         [JsonProperty("Value")]
         public string Value { get; set; }

         [JsonProperty("IsNull")]
         public bool IsNull { get; set; }

         [JsonProperty("Name")]
         public string Name { get; set; }

      }

      /// <summary>
      /// Changes 配列の要素を表すクラス
      /// </summary>
      public class Change
      {
         [JsonProperty("Action")]
         public int Action { get; set; }

         [JsonProperty("ItemNo")]
         public int ItemNo { get; set; }

         [JsonProperty("UpdateLocking")]
         public int UpdateLocking { get; set; }

         [JsonProperty("Properties")]
         public List<Property> Properties { get; set; } = new List<Property>();

         [JsonProperty("ItemId")]
         public string ItemId { get; set; }

      }

      /// <summary>
      /// JSON全体のルートオブジェクトを表すクラス
      /// </summary>
      public class UpdateJSONObject
      {
         [JsonProperty("Changes")]
         public List<Change> Changes { get; set; } = new List<Change>();

         [JsonProperty("IDOName")]
         public string IDOName { get; set; }

      }

      /// <summary>
      /// データをアップデート・取得する
      /// </summary>
      /// <param name="mode">操作モード（0:取得, 1:挿入, 2:更新, 4:削除）</param>
      /// <param name="IDOName">IDO名</param>
      /// <param name="propertiesList">プロパティリスト</param>
      /// <returns>APIレスポンスのJSON文字列</returns>      
      private string getData(int mode ,string IDOName ,List<Property> propertiesList){
         // 呼び出すAPIを設定
         string sso = gSSO;                        // SSOの使用、基本は1　1：はい　0：いいえ
         string serverId = gServerId;              // APIサーバのID、詳しくはAPIサーバ関連
         string suiteContext = gSuiteContext;      // APIスイートのコンテキスト、同上
         string httpMethod = "";                   // APIメソッドのHTTP接続し設定、同上
         string methodName = "";                   // APIメソッドの名前、同上、IDO名以降の部分は動的にできそう
         string parameters = "";                   // APIパラメータ設定、一部パラメータはメソッド名で設定できるが、ここはURL上で設定できない部分を書く（ヘッダーなど）
         string contentType = gContentType;        // 返り値のタイプ、基本設定不要もしくは"application/json"
         string timeout = gTimeout;                // タイムアウト設定

         // 使用するメソッド（APIのエンドポイント）を設定
         if(mode == 0){
            // getの場合
            httpMethod = "GET";
            // APIのURL + IDO名 + 取得プロパティ
            methodName = $"/IDORequestService/ido/load/{IDOName}?properties={string.Join( ", ", propertiesList.Select(p => p.Name) )}{GenerateFilter()}";
         }
         else{
            // postの場合
            httpMethod = "POST";
            // APIのURL + IDO名 + 取得パラメータ
            methodName = $"/IDORequestService/ido/update/{IDOName}?refresh=true";
         }

         // パラメータのHeader部分（基本共通）
         string headerTemp = $"{{\"Name\":\"X-Infor-MongooseConfig\",\"Type\":\"Header\",\"Value\":\"{gSiteName}\"}}";

         // パラメータを設定
         if(mode == 0){
            // getの場合
            // 基本Headerのみ
            parameters = $"[{headerTemp}]";
         }
         else{
            // postの場合
            // Body部分、動的生成する必要がある
            string bodyTemp = $"{{\"Name\":\"Body\",\"Type\":\"Body\",\"Value\":\'{GenerateChangeSetJson(mode,IDOName,propertiesList)}\'}}";

            // 結合
            parameters = $"[{headerTemp},{bodyTemp}]";;
            
         }

         // API呼び出し
         InvokeRequestData IDORequest = new InvokeRequestData();  //APIメソッド呼び出し用
         InvokeResponseData response;                             //結果受け取り用

         // API呼び出すためのIDOメソッドを設定
         // APIを直で呼び出せないため、IDOメソッドを経由
         // また、LoadCollectionメソッドは同アプリ（mongoose）同サイト（default）のみ呼び出すため不採用
         IDORequest.IDOName = "IONAPIMethods";
         IDORequest.MethodName = "InvokeIONAPIMethod";

         // パラメータ設定
         IDORequest.Parameters.Add(new InvokeParameter(sso));
         IDORequest.Parameters.Add(new InvokeParameter(serverId));
         IDORequest.Parameters.Add(new InvokeParameter(suiteContext));
         IDORequest.Parameters.Add(new InvokeParameter(httpMethod));
         IDORequest.Parameters.Add(new InvokeParameter(methodName));
         IDORequest.Parameters.Add(new InvokeParameter(parameters));
         IDORequest.Parameters.Add(new InvokeParameter(contentType));
         IDORequest.Parameters.Add(new InvokeParameter(timeout));
         IDORequest.Parameters.Add(new InvokeParameter(IDONull.Value)); //ResponseCode
         IDORequest.Parameters.Add(new InvokeParameter(IDONull.Value)); //ResponseContent
         IDORequest.Parameters.Add(new InvokeParameter(IDONull.Value)); //ResponseHeaders
         IDORequest.Parameters.Add(new InvokeParameter(IDONull.Value)); //ResponseInfobar

         // メソッド呼び出し
         response = IDOClient.Invoke(IDORequest);

         // エラーハンドラ
         if (response.IsReturnValueStdError())
         {
            // get infobar output parameter
            string errorMsg = null;
            errorMsg = response.Parameters[8].Value;
            errorMsg += "\r\n" + response.Parameters[11].Value;
            throw new Exception(string.Format("Trigger of IONAPI Method Failed : {0}", errorMsg));
         }

         // getの場合
         if(mode == 0){
            //データを画面に表示
            return response.Parameters[9].Value;
         }

         // postの場合
         // データや_itemIDの更新後の状況を取得するため、getで再帰呼び出し
         //return getData(0, IDOName, propertiesList);

         // webに移行、grid更新する必要がなくなった
         return "";
      }

      /// <summary>
      /// Update用JSON文字列を自動生成する
      /// </summary>
      /// <param name="mode">操作モード（0:取得, 1:挿入, 2:更新, 4:削除）</param>
      /// <param name="IDOName">IDO名</param>
      /// <param name="propertiesList">プロパティリスト</param>
      /// <returns>Update用JSON文字列</returns>
      private string GenerateChangeSetJson(int mode ,string IDOName ,List<Property> propertiesList)
      {
         // 1. ルートオブジェクトを作成
         var root = new UpdateJSONObject
         {
            IDOName = IDOName
         };

         // 2. Changeオブジェクトを作成
         var change = new Change
         {
            Action = mode,
            ItemId = "new1"
         };

         foreach(Property prop in propertiesList){
            // 3. Propertyオブジェクトを必要な分だけ作成し、Changeオブジェクトのリストに追加
            change.Properties.Add(prop);

            //キー指定する場合、ItemIDを指定されたキーと同値にする（mode = 2,4のみ）
            if(!prop.Modified && change.ItemId == "new1"){
               change.ItemId = prop.Value;
            }
         }

         // 4. Changeオブジェクトをルートオブジェクトのリストに追加
         root.Changes.Add(change);

         // 5. オブジェクトをJSON文字列にシリアライズ
         // Formatting.Indented を付けると整形された見やすいJSONが出力される
         string jsonString = JsonConvert.SerializeObject(root, Formatting.Indented);

         return jsonString;
      }

   }
}

