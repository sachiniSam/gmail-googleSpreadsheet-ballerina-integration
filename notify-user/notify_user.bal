import ballerina/config;
import ballerina/log;
import wso2/gsheets4;
import wso2/gmail;
import ballerina/io;



documentation{A valid access token with gmail and google sheets access.}
string accessToken = config:getAsString("ACCESS_TOKEN");

documentation{The client ID for your application.}
string clientId = config:getAsString("CLIENT_ID");

documentation{The client secret for your application.}
string clientSecret = config:getAsString("CLIENT_SECRET");

documentation{A valid refreshToken with gmail and google sheets access.}
string refreshToken = config:getAsString("REFRESH_TOKEN");

documentation{Spreadsheet id of the reference google sheet.}
string spreadsheetId = config:getAsString("SPREADSHEET_ID");

documentation{Sheet name of the reference googlle sheet.}
string sheetName = config:getAsString("SHEET_NAME");

documentation{Sender email address.}
string senderEmail = config:getAsString("SENDER");

documentation{The user's email address.}
string userId = config:getAsString("USER_ID");

documentation{
    Google Sheets client endpoint declaration with http client configurations.
}
endpoint gsheets4:Client spreadsheetClient {
    clientConfig:{
        auth:{
            accessToken:accessToken,
            refreshToken:refreshToken,
            clientId:clientId,
            clientSecret:clientSecret
        }
    }
};

documentation{
    GMail client endpoint declaration with oAuth2 client configurations.
}

endpoint gmail:Client gmailClient {
    clientConfig:{
        auth:{
            accessToken:accessToken,
            refreshToken:refreshToken,
            clientId:clientId,
            clientSecret:clientSecret
        }
    }
};


documentation{
main function which directs to spreadsheet
}
function main(string... args) {

    boolean succ =  accessDb();

}


documentation{
  check if the current mediccal products are less than needed, if true, then send an email
  to the respective company mentioning the product we need to purchase.
}
function accessDb() returns(boolean)  {
    //retrieve company details from the google spreadsheet
    var companyDetails = getCompanyDetails();


    match companyDetails {
        string[][] values => {
            int i =0;
            //Iterate through each company to check if the medical products are less than expected.
            foreach value in values {
                //avoid header row
                if(i > 0) {
                    string companyId = value[0];
                    string compayName = value[1];
                    string companyEmail = value[2];
                    string productName = value[3];
                    string productQuantity = value[4];

                    string subject = "In Need to purchase more products " + compayName;

                    //obtain the products count of the current medicine
                    int proCount = check <int>companyId;
                    //if the current count is less than 25, then an email is sent.
                    if (proCount<25) {
                        boolean isSuccess = sendMail(companyEmail, subject,
                               untaint getCustomEmailTemplate(compayName, productName));
                          if (!isSuccess) {
                               return false;
                           }
                    }

                }
                i = i +1;
            }
        }
        boolean isSuccess => return isSuccess;
    }

    return true;


}

documentation{
    retireive compamy details from the spreadsheet
}

function getCompanyDetails () returns (string[][]|boolean) {

    string[][] values;
    var spreadsheetResults =  spreadsheetClient->getSheetValues(spreadsheetId, sheetName,"","");

    match spreadsheetResults {
        string[][] vals => {
            log:printInfo("Retrieved company details from spreadsheet id:" + spreadsheetId + " ; sheet name: "
                    + sheetName);
            log:printInfo("get Company data GSheet finish");
            return vals;
        }

        gsheets4:SpreadsheetError e => {
            log:printInfo(e.message);
            return false;
        }
    }

}

documentation{
function to send mail to relevant companies
}
function sendMail(string customerEmail, string subject, string messageBody) returns (boolean) {

    //customize the email according to the details provided
    gmail:MessageRequest messageRequest;
    messageRequest.recipient = customerEmail;
    messageRequest.sender = senderEmail;
    messageRequest.subject = subject;
    messageRequest.messageBody = messageBody;
    messageRequest.contentType = gmail:TEXT_HTML;

    //Send mail
    var sendMessageResponse = gmailClient->sendMessage(userId, untaint messageRequest);
    string messageId;
    string threadId;
    match sendMessageResponse {
        (string, string) sendStatus => {
            (messageId, threadId) = sendStatus;
            log:printInfo("Sent email to " + customerEmail + " with message Id: " + messageId + " and thread Id:"
                    + threadId);
            log:printInfo("Send Mail Function finish");
            return true;

        }
        gmail:GmailError e => {
            log:printInfo(e.message);
            return false;
        }
    }

}

documentation{
customize the email body with the given data
}
function getCustomEmailTemplate(string companyName, string productName) returns (string) {
    string emailTemplate = "<h3> Hi " + companyName + " </h3>";
    emailTemplate = emailTemplate + "<h3> In need of more products! </h3>";
    emailTemplate = emailTemplate + "<p>As we are current in Less stock of your product- "+ productName+" ,we would be pleased if you can deliver more.</p>";
    emailTemplate = emailTemplate + "<p>Please contact us regarding the quantity of the " + productName +
        ", that you need to deliver.</p> ";
    return emailTemplate;
}


