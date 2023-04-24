// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

// string tempvar = 'Enter_your_name_here';
// System.debug('Hello World!');
// System.debug('My name is ' + tempvar);

public class Return_MessagesBot
{
    List<String> mUId {get ; set;}

    List<String> mSId {get ; set;}

    Map<String, MessagingSession> sessionsBot;

    Return_MessagesBot()
    {
        this.mUId = new List<String>();
        this.mSId = new List<String>();
        this.sessionsBot = new  Map<String, MessagingSession>();
    }
} 

public class Return_Responses
{
    public Boolean ConsentimientoPrevio {get;set;}

    public Boolean Consentimiento {get;set;}

    public Boolean Respondido {get;set;}
   
    public Datetime fechaRespuesta {get ; set;}

    public String IdRespuesta {get ; set;}

    public Return_Responses()
    {
        this.ConsentimientoPrevio = false;
        this.Consentimiento = false;
        this.fechaRespuesta = null;
        this.Respondido = false;
    }
}

public  class Functions 
{
     public  Return_MessagesBot LoadMessagesBot(DateTime dateIn ,Datetime dateFn)
     {
         List<MessagingSession> msTO = [SELECT Id, Name, MessagingEndUserId, MessagingEndUser.Name, MessagingEndUser.MessagingConsentStatus, MessagingEndUser.MessagingPlatformKey, Origin, CreatedDate FROM MessagingSession WHERE (CreatedDate >=:dateIn AND  CreatedDate <=:dateFn) and Origin = 'TriggeredOutbound'
            AND ChannelType = 'WhatsApp'];//revisa whatsapps de salida entre dos fechas
         system.debug('@@@@ msTO '+msTO.size());

        Return_MessagesBot RMB = new Return_MessagesBot();

        for (MessagingSession m : msTO)
        {
            RMB.mUId.add(m.MessagingEndUserId);
            RMB.mSId.add(m.Id);
            RMB.sessionsBot.put(m.Id, m);
        }

        return RMB;
     }

   public  List<ConversationEntry>  getConversations(List<String> mSId)
    {
        List<ConversationEntry> conversations = [
            SELECT Id, ConversationId, Conversation.Name, MessageStatus, MessageStatusCode, MessageSendTime, MessageReadTime, MessageDeliverTime, MessageIdentifier, Message, CreatedDate, EntryTime
            FROM ConversationEntry
            WHERE ConversationId IN : mSId order by CreatedDate ASC];
            return conversations;
    }

    public String getReportNumber(List<ConversationEntry> conversations, String conversationId)
    {
        String idDenuncio = '';
        for (ConversationEntry entry : conversations)
        {
            if (entry.ConversationId == conversationId && String.isNotBlank(entry.Message))
            {
                if (entry.Message.contains('tu número de siniestro es'))
                {
                    String message = entry.Message;

                    String[] values =  message.split('tu número de siniestro es');
          
                    idDenuncio = values[1].split('\\.')[0];
                    break;
                }
            }
        }

        return idDenuncio;
    } 


   public  List<MessagingSession>  LoadResponsesClient(List<String> mUId)
    {
        List<MessagingSession> msII = [SELECT Id, Name, MessagingEndUserId, MessagingEndUser.Name, MessagingEndUser.MessagingConsentStatus, MessagingEndUser.MessagingPlatformKey, Origin, CreatedDate 
                                    FROM MessagingSession 
                                    WHERE Origin = 'InboundInitiated' AND MessagingEndUserId IN : mUId order by CreatedDate ASC];

        return msII;
    }


    //  public  List<MessagingSession>  LoadResponsesClient(List<String> mUId, Datetime vDate)
    // {
    //     List<MessagingSession> msII = [SELECT Id, Name, MessagingEndUserId, MessagingEndUser.Name, MessagingEndUser.MessagingConsentStatus, MessagingEndUser.MessagingPlatformKey, Origin, CreatedDate 
    //                                 FROM MessagingSession 
    //                                 WHERE Origin = 'InboundInitiated' AND CreatedDate >=: vDate AND MessagingEndUserId IN : mUId order by CreatedDate ASC];

    //     return msII;
    // }
    

    ///get date 
    public Return_Responses getResponse(List<MessagingSession>  responsesClient, String mUId, Datetime dateMessageBot)
    {
        List<MessagingSession> msII = new List<MessagingSession>();

        for (MessagingSession entry : responsesClient)
        {
            if (entry.Id == mUId)
            {
                msII.add(entry);
            }
        }

        Return_Responses response = null;

        if (msII.size() == 0)
        {
            response = new Return_Responses();
            return response;
        }

        response = new Return_Responses();

        for (MessagingSession entry : msII)
        {
            if (entry.CreatedDate < dateMessageBot)
            {
                response.ConsentimientoPrevio = true;
            }
            else if (entry.CreatedDate >= dateMessageBot && response.fechaRespuesta == null)
            {
                response.IdRespuesta = entry.Id;
                response.fechaRespuesta = entry.CreatedDate;
                response.Respondido = true;
                response.consentimiento = true;
            }
            // else
            // {
            //     response.IdRespuesta = m.Id;
            //     response.fechaRespuesta = m.CreatedDate;
            //     response.consentimiento = true;
            //     response.Respondido = true;
            // }
        }


        return response;
    } 
}

Functions fn = new Functions();
Date vDateIn = Date.newInstance(2023, 3, 27);
Date vDateFn = Date.newInstance(2023, 4, 20);

Return_MessagesBot RMB = fn.LoadMessagesBot(vDateIn, vDateFn);
system.debug('@@@@ msTO '+RMB.mUId.size());
system.debug('@@@@ msTO '+RMB.mSId.size());

List<ConversationEntry> conversations = fn.getConversations(RMB.mSId);
system.debug('@@@@ conversations '+conversations.size());

String denuncio = '';

List<MessagingSession> responsesClients = LoadResponsesClient(RMB.mUId);
Return_Responses response = null;

for (MessagingSession ms : RMB.sessionsBot)
{
  //  denuncio = getReportNumber(conversations, ms.Id);
    response = getResponse(responsesClients, ms.Id, ms.CreatedDate);
}




/*
xssssss
public class Objeto
{
   // public String Estado {get ; set;}

    public String Mensaje {get ; set;}

    public String Origen {get ; set;}

    public String ConsentStatus {get ; set;}

    public String WhatsAppNumber {get ; set;}

    public String Name {get ; set;}

    public String MessagingEndUserId {get ; set;}

    public String Siniestro {get ; set;}

    public String IdConversation {get ; set;}

    public String IdRespuesta {get ; set;}

    public Datetime fechaEnvio {get ; set;}

    public String fechaRespuesta {get ; set;}

    public String Respuesta {get ; set;}

    public Objeto()
    {
        this.Respuesta = 'NO';
        this.fechaRespuesta = '';
    }

}


 */
//obtener denuncio


// List<MessagingSession> responses = fn.LoadResponsesClient(RMB.mUId);
// system.debug('@@@@ responses '+responses.size());

// for (MessagingSession ms : RMB.sessionsBot)
// {
//     denuncio = getReportNumber(conversations, ms.Id);
// }