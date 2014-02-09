<%@ page import = "se.sics.prologbeans.*" %>
<html>
<head><title>Summa Calculator</title></head>
<body bgcolor="white">
<font size=4>Prolog Sum Calculator, enter expression to evaluate and sum-up!
<form><input type=text name=query></form>

<%
   PrologSession pSession = PrologSession.getPrologSession("prolog/PrologSession", session);

   String evQuery = request.getParameter("query");
   String output = "";
   if (evQuery != null) {
     Bindings bindings = new Bindings().bind("E",evQuery + '.');
     QueryAnswer answer = pSession.executeQuery("sum(E,Sum,Average,Count)",
			                        bindings);

     Term average = answer.getValue("Average");
     if (average != null) {
        Term sum = answer.getValue("Sum");
        Term count = answer.getValue("Count");

	output = "<h4>Average =" + average + ", Sum = "
	+ sum + " Count = " + count + "</h4>";
     } else {
        output = "<h4>Error: " + answer.getError() + "</h4>";
     }
  }
%>
<%= output  %><br>
</font>
<p><hr>Powered by SICStus Prolog
</body>
</html>
