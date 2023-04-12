// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

// string tempvar = 'Enter_your_name_here';
// System.debug('Hello World!');
// System.debug('My name is ' + tempvar);

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

    public Datetime fechaRespuesta {get ; set;}

    public Boolean Respuesta {get ; set;}

    public Objeto()
    {
        this.Respuesta = false;
    }

}

public class DataResponse
{
     public Datetime fechaRespuesta {get ; set;}

     public String IdRespuesta {get ; set;}
}

//public void ExecutaAccion(DateTime vDate)
//{

    Date vDate = Date.newInstance(2023, 4, 11);

    DateTime vDateIni = DateTime.newinstance(vDate.year(), vDate.month(), vDate.day(), 0, 0, 0);
    DateTime vDateFin = DateTime.newinstance(vDate.year(), vDate.month(), vDate.day(), 23, 59, 59);

    List<MessagingSession> msTO = [SELECT Id, Name, MessagingEndUserId, MessagingEndUser.Name, MessagingEndUser.MessagingConsentStatus, MessagingEndUser.MessagingPlatformKey, Origin, CreatedDate FROM MessagingSession WHERE (CreatedDate >=:vDateIni AND  CreatedDate <=:vDateFin) and Origin = 'TriggeredOutbound'
    ];

    List<String> mUId = new List<String>();

    List<String> mSId = new List<String>();

    for (MessagingSession m : msTO)
    {
        mUId.add(m.MessagingEndUserId);
        mSId.add(m.Id);
    }

    List<ConversationEntry> conversations = [
    SELECT Id, ConversationId, Conversation.Name, MessageStatus, MessageStatusCode, MessageSendTime, MessageReadTime, MessageDeliverTime, MessageIdentifier, Message, CreatedDate, EntryTime 
    FROM ConversationEntry 
    WHERE ConversationId IN : mSId order by CreatedDate desc];

    String idDenuncio = '';

    Map<String, String> mapConversations = new Map<String, String>();

    for (ConversationEntry entry : conversations)
    {
        if (String.isNotBlank(entry.Message))
        {
            if (entry.Message.contains('tu número de siniestro es'))
            {
                String message = entry.Message;

                String[] values =  message.split('tu número de siniestro es');
                // system.debug('@@@@ values.size'+values.size());
                //if (values.size() == 3)
                //{
                idDenuncio = values[1].split('\\.')[0];
                // system.debug('@@@@ idDenuncio --> '+idDenuncio);
                mapConversations.put(entry.ConversationId, idDenuncio);
                //}
            }
        }
    }

    system.debug('@@@@ mUId.size'+mUId.size());

    List<MessagingSession> msII = [SELECT Id, Name, MessagingEndUserId, MessagingEndUser.Name, MessagingEndUser.MessagingConsentStatus, MessagingEndUser.MessagingPlatformKey, Origin, CreatedDate 
                                    FROM MessagingSession 
                                    WHERE CreatedDate >=: vDateIni and Origin = 'InboundInitiated' AND MessagingEndUserId IN : mUId order by CreatedDate ASC];

    Map<String, DataResponse> mapSessions = new Map<String, DataResponse>();
    
    for (MessagingSession m : msII)
    {
        DataResponse dr = new DataResponse();
        dr.IdRespuesta = m.Id;
        dr.fechaRespuesta = m.CreatedDate;
        mapSessions.put(m.MessagingEndUserId, dr);
    }

    Objeto obj = null;

    List<Objeto> objs = new List<Objeto>();

    Integer offset = null;
    Datetime local = null;
    Datetime vSendDate= null;
    Datetime vReceivedDate= null;

    for (MessagingSession m : msTO)
    {
        //obj.Estado = '';
        obj = new Objeto();
        obj.ConsentStatus = m.MessagingEndUser.MessagingConsentStatus;
        obj.Mensaje = m.Name;
        obj.Origen = m.Origin;
        obj.Name = m.MessagingEndUser.Name;
        obj.MessagingEndUserId = m.MessagingEndUserId;
        String[] values =   m.MessagingEndUser.MessagingPlatformKey.split(':');
        // system.debug('@@@@ v[0]  --> '+ values[0]);
        // system.debug('@@@@ v[1]  --> '+ values[1]);
        obj.WhatsAppNumber = values[1];

        vSendDate =  m.CreatedDate;
        offset = UserInfo.getTimezone().getOffset(vSendDate);
        local = vSendDate.addSeconds(offset/1000);
        obj.fechaEnvio = local;
        //obj.Respuesta = false;

        if (mapConversations.containsKey( m.Id))
        {
            obj.Siniestro = mapConversations.get(m.Id);
        }

        if (mapSessions.containsKey( m.MessagingEndUserId))
        {
            DataResponse dr =  mapSessions.get(m.MessagingEndUserId);

            vReceivedDate =  dr.fechaRespuesta;
            offset = UserInfo.getTimezone().getOffset( vReceivedDate);
            local = vReceivedDate.addSeconds(offset/1000);

            obj.fechaRespuesta = local;
            obj.IdRespuesta = dr.IdRespuesta;
            obj.Respuesta = true;
        }

        obj.IdConversation = m.Id;

        if (String.isNotBlank(obj.Siniestro))
        {
            objs.add(obj);
        }
    }

    /*
    
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

    public Datetime fechaRespuesta {get ; set;}

    public Boolean Respuesta {get ; set;}
     */

    string header = 'Mensaje, Celular , Nombre, Siniestro, FechaEnvio, FechaRespuesta, Respuesta \n';
    string finalstr = header ;

    for (Objeto ob : objs)
    {
       string recordString = ob.Mensaje+','+ob.WhatsAppNumber+','+ob.Name+','+ob.Siniestro+','+ob.fechaEnvio+','+ob.fechaRespuesta+','+ob.Respuesta +'\n';

       finalstr = finalstr +recordString;
        system.debug('@@@@  --> '+ ob);
    }



Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
blob csvBlob = Blob.valueOf(finalstr);
string csvname= 'WhatsApp.csv';
csvAttc.setFileName(csvname);
csvAttc.setBody(csvBlob);
Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
//String[] toAddresses = new list<string> {'edward.mitchell@hdi.cl', 'juan.espinoza@hdi.cl'};
String[] toAddresses = new list<string> {'juan.espinoza@hdi.cl'};
String subject ='WhatsApp CSV --> '+ vDate.format();
email.setSubject(subject);
email.setToAddresses( toAddresses );
email.setPlainTextBody('WhatsApp CSV ');
email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});

//     CSVWriter writer = new CSVWriter('MiArchivoCSV.csv');

// // Escribir los encabezados de las columnas
// writer.writeNext(new List<String>{'Nombre', 'Apellido', 'Correo electrónico'});

// // Escribir los datos
// writer.writeNext(new List<String>{'Juan', 'Espinoza', 'juan.espinoza@email.com'});
// writer.writeNext(new List<String>{'María', 'Gómez', 'maria.gomez@email.com'});

// // Cerrar el archivo
// writer.close();

//}

//DateTime vDate = DateTime.newinstance(2023, 04, 11, 0, 0, 0);
//ExecutaAccion(vDate);




