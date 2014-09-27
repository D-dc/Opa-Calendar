//
// src/view/view_calendar.opa
// @date: 03/2013
// @author: Diel Caroes
//
//  This module handles the GUI for the calendar.
//

module ViewCalendar{
    /*
        Handle changes (can be caused by clicking previous, next buttons etc)
    */
    client function session_calendar_handler({~current_date}, message){
        match(message){
            
            case {calendarnow}:
                //Generate the current calendar
                calendar(current_date)
                highlightMeetings();
                {unchanged}
      
            case {calendarprev}:
                //generate calendar of previous month 
                newDate=Date.advance_by_days(current_date, -(Date.get_day(current_date)))
                calendar(newDate)
                highlightMeetings();
                {set: {current_date: newDate}}
      
            case {calendarnext}:
                //generate calendar of next month
                newDate=Date.advance_by_days(current_date, (Calendar.month_days(current_date)-Date.get_day(current_date))+1);
                calendar(newDate)
                highlightMeetings();
                {set: {current_date: newDate}}  
      
            case {stop}: 
                {stop}

            default: 
                {unchanged}
        }
    }

    /*
        Generate the calendar, highlight meetings
    */
    client function calendar(currentDate){
        #calendar=calendarGenerate(currentDate);
    }

    /*
        Generates the HTML for the actual calendar
    */
    client private function calendarGenerate(Date.date today){
        firstDay = Calendar.toFirstOfMonth(today);//Go to the first day of this month
        current = Calendar.toFirstMondayOfCurrentWeek(firstDay);
        int daysInWeek=7;
        //all calendar possibilities with for example a new month starting on a sunday fit in 6rows of 7days. We add another row for the names of the day of the week 
        int rowsNeeded = 7; 

        currentMonthDays = Calendar.month_days(today); //days in the current month

        /* if the first of a month is on a sunday and the month counts 31 days then we need max 7 rows of 7 days (6 +1 for header)*/
        
        WGrid.size grootte = {rows: rowsNeeded, cols: daysInWeek}
        dates = WGrid.create(grootte)

        WGrid.styling st = {styler: WStyler.make_class(["cell"])};
        dates = WGrid.fill(dates, function(pos){
            /* Print the days of the week header*/
            if(pos.row==0){
                list(string) month_days = ["M", "T", "W", "T", "F", "S", "S"];
                <b><u>{List.get(pos.col, month_days)}</u></>
            }else{
                /* Fill the rest of the calendar according to which day every cell corresponds*/
                number = ((pos.row-1)*7+pos.col+1)-1;
                currentDay=Date.advance_by_days(current, number);
                dayNr   = Date.get_day(currentDay);
                monthNr = Date.get_month(currentDay);

                int id=Date.in_milliseconds(Date.round_to_day(currentDay));

                if(monthNr==Date.get_month(today)){

                    cell=<b id={id} onclick={function(_){
                      
                        Dom.show(#meeting_viewer);
                        Dom.set_value(#meeting_date, {Date.to_formatted_string(Date.generate_printer("%d/%m/%Y %R"), currentDay)}); //%A %B %d %Y %R
                        ViewEvent.showMeetings(Date.round_to_day(currentDay));
                        ClientEvents.meetingOnDay(currentDay);
                    }}>{dayNr}</>;

                    if(Date.round_to_day(Date.now())==Date.round_to_day(currentDay)){//highlight today
                        <u>{cell}</>
                    }else{
                        cell
                    }
                }else{
                    <span class=otherMonth>{dayNr}</>
                }  
            }
        })
        
        header=Date.to_formatted_string(Date.generate_printer("%B - %Y"), firstDay);
        frame = <><h2 title="{currentMonthDays} days">{header} <small>{currentMonthDays} days</small></>{WGrid.render(dates,function(cell){
            WGrid.rendered_cell a={xhtml: cell, style: st}
            a
        }, st)}</>
        frame
    }

    /*
        Unhighlight every event on the calendar (function is only used when a reset of the localstorage is requested)
    */
    function unhighlightMeetings(){
        //only way to remove old highlights
        ClientEvents.localEvents(function(evt event){

            ClientEvents.unHighlightOnCalendar(event.event_date);

        });
    }

    /*
        Highlight every event on the calendar of the current month (function is only used when the calendar is started or an other month is requested)
    */
    function highlightMeetings(){
        
        ClientEvents.localEvents(function(evt event){
                    
            ClientEvents.highlightOnCalendar(event.event_date);

        });
    }


  /*
    We create a session to store current calendar date 
    this avoids the use of a mutable in calendar.opa and is faster.
  */
  function open_calendar(){

    channel = Session.make({current_date:Date.now()}, session_calendar_handler)

    function Calendar_default(){
          <div>
            <div id=calendar>{Session.send(channel, {calendarnow})}</>
            <div class="btn-group">
              <button class="btn btn-primary" onclick={function(_){//some effects
                Dom.transition(#CalendarFull, Dom.Effect.with_duration({fast}, Dom.Effect.fade_out()))
                Session.send(channel, {calendarprev})
                Dom.transition(#CalendarFull, Dom.Effect.with_duration({slow}, Dom.Effect.fade_in()))
                void
              }}><i class="icon-backward icon-white"> </i> Previous</>
              <button class="btn btn-primary" onclick={function(_){//some effects
                Dom.transition(#CalendarFull, Dom.Effect.with_duration({fast}, Dom.Effect.fade_out()))
                Session.send(channel, {calendarnext})
                Dom.transition(#CalendarFull, Dom.Effect.with_duration({slow}, Dom.Effect.fade_in()))
                void
              }}>Next <i class="icon-forward icon-white"> </i></>
            </>
          </>
    }

    #main = 
      <div class="row">
        <div class="span6" id=CalendarFull>
          {Calendar_default()}
        </>
        <div class="span6">
          {ViewEvent.EventViewerScreen()}
          {ViewEvent.EventSchedulerScreen()} 
          {ViewEvent.EventEditScreen()}
        </>
      </>
  }

}