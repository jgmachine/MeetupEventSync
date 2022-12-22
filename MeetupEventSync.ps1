#Requires -Modules Selenium, PSGSuite

# Function to get Meetup Event data
Function Get-MeetupEventData {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$MeetupEventsUrl
    )
    $Driver = Start-SeChrome -Headless -StartURL $MeetupEventsUrl -quiet
    $MeetupEvents = $Driver.FindElementByCssSelector('#mupMain > div.groupPageWrapper--child > div.child-wrapper > div > div > div > div.flex-item.flex-item--4 > div > div > ul').FindElementsByClassName('list-item')

    $EventLinks= @()
    foreach ($event in $MeetupEvents) {
        $EventLinks += $event.FindElementByClassName('eventCard--link').GetProperty('href')
    }

    $MeetupEventsHT = @{}
    foreach ($event in $EventLinks) {
        $driver | Enter-SeUrl $event

        # Get start and end date and time
        $timeRange = $driver.FindElementByTagName('time').text.Split(' to ')
        
        $EventDetails = [PSCustomObject]@{
            EventID = $event.Split('/')[-2]
            EventTitle = $driver.FindElementByCssSelector('#main > div.w-full.border-b.border-shadowColor.bg-white.px-5.py-2.lg\:py-6 > div > h1').Text
            StartDateTime = [datetime]::Parse($timeRange[0].replace('at ',''))
            EndDateTime = [datetime]::Parse($timeRange[1].replace('at ','').replace(' PST','').replace(' PDT',''))
            VenueName = $driver.FindElementByCssSelector('#main > div.bg-gray1.w-full.flex.flex-col.items-center.justify-between.lg\:px-5.border-t.border-gray2.pb-6 > div.md\:max-w-screen.w-full.bg-gray1 > div > div.w-100.lg\:w-90.lg\:mx-0.lg\:ml-28.lg\:mt-10 > div.top-24.sticky > div.mt-5.text-sm > div.px-5.py-3.sm\:pb-4\.5.lg\:py-5.bg-white.lg\:rounded-t-2xl > div:nth-child(1) > div.flex.mt-5 > div.pl-4.md\:pl-4\.5.lg\:pl-5.overflow-hidden > a').Text
            VenueAddress = $driver.FindElementByCssSelector('#main > div.bg-gray1.w-full.flex.flex-col.items-center.justify-between.lg\:px-5.border-t.border-gray2.pb-6 > div.md\:max-w-screen.w-full.bg-gray1 > div > div.w-100.lg\:w-90.lg\:mx-0.lg\:ml-28.lg\:mt-10 > div.top-24.sticky > div.mt-5.text-sm > div.px-5.py-3.sm\:pb-4\.5.lg\:py-5.bg-white.lg\:rounded-t-2xl > div:nth-child(1) > div.flex.mt-5 > div.pl-4.md\:pl-4\.5.lg\:pl-5.overflow-hidden > div.text-gray6').Text
            Description = $driver.FindElementByCssSelector('#main > div.bg-gray1.w-full.flex.flex-col.items-center.justify-between.lg\:px-5.border-t.border-gray2.pb-6 > div.md\:max-w-screen.w-full.bg-gray1 > div > div.flex.flex-col.flex-grow.lg\:mt-5 > div > div.emrv9za > div.px-6.sm\:px-4.xl\:px-0.md\:max-w-screen.w-full.mt-5 > div.break-words').Text
        }
        $MeetupEventsHT[$EventDetails.EventID] = $EventDetails
    }
    Stop-SeDriver -Driver $Driver
    return $MeetupEventsHT
}

# Function to get Google Calendar Event data
Function Get-GoogleCalendarEventData {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$PSGSuiteConfig,
        [Parameter(Mandatory)]
        [string]$CalendarId
    )
    Set-PSGSuiteConfig $PSGSuiteConfig
    $GoogleEvents = Get-GSCalendarEventList -CalendarId $CalendarId -TimeMin (get-date) -TimeMax (get-date).AddDays(33)
    $GoogleEventsHT = @{}
    foreach ($event in $GoogleEvents) {
        $id = $event.description.substring($event.description.Length - 8)
        $GoogleEventsHT[$id] = $event
    }
    return $GoogleEventsHT
}
