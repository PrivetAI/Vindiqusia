import Foundation

/// One page per Hijri month: what the name means, where it sits, and what is attached to it.
struct HJMonthPage: Identifiable {
    var id: Int { number }
    let number: Int
    /// A short line under the name, used in lists.
    let epithet: String
    /// Where the name comes from.
    let meaning: String
    /// Its place in the year.
    let position: String
    let isSacred: Bool
    /// What the month carries.
    let associations: String
    /// Length in an ordinary year of this calendar.
    var ordinaryLength: Int { number == 12 ? 29 : (number % 2 == 1 ? 30 : 29) }

    var sacredLine: String {
        isSacred
            ? "One of the four sacred months, in which fighting was to be set aside."
            : "Not one of the four sacred months."
    }
}

enum HJMonthLibrary {

    static let pages: [HJMonthPage] = [

        HJMonthPage(number: 1,
                    epithet: "The forbidden month",
                    meaning: "The name shares a root with the word for what is forbidden or set apart. It marked a month in which fighting was not permitted, and the name outlived the practice.",
                    position: "The first month of the year. The Hijri year turns on its first day, counted from the migration to Medina in 622 CE.",
                    isSacred: true,
                    associations: "Ashura falls on its tenth, kept as a voluntary fast and, for Shia Muslims, as the anniversary of Karbala. Voluntary fasting through the month is long-established. It is one of the three sacred months that run consecutively, together with the two that close the previous year."),

        HJMonthPage(number: 2,
                    epithet: "The empty month",
                    meaning: "Usually explained from a root meaning empty, or from one meaning yellow. The common account is that houses stood empty once the sacred month ended and people left to travel and trade again.",
                    position: "The second month, immediately after Muharram. It has no fixed observance of its own.",
                    isSacred: false,
                    associations: "Pre-Islamic custom treated Safar as unlucky, a reading that Islamic teaching explicitly rejected. The month carries no prescribed rite. The only regular days in it are the weekly and monthly voluntary fasts that fall in every month."),

        HJMonthPage(number: 3,
                    epithet: "The first spring",
                    meaning: "Rabi means spring, or the season of grazing. The pair of Rabi months were named for the time of year they originally fell in, before the calendar was cut loose from the seasons.",
                    position: "The third month. Because the Hijri year is about eleven days shorter than the solar year, it long ago stopped landing in spring and now moves through all of them.",
                    isSacred: false,
                    associations: "The birth of the Prophet is placed in this month, and the Mawlid is kept by much of the Muslim world on its twelfth; many Shia communities keep the seventeenth. The Prophet's death is also placed in Rabi al-Awwal, in the year 11 AH."),

        HJMonthPage(number: 4,
                    epithet: "The second spring",
                    meaning: "The companion to Rabi al-Awwal, and named simply as the second of the pair. It is also written Rabi al-Akhir, meaning the later Rabi.",
                    position: "The fourth month, closing the pair. Like Safar it carries no fixed observance.",
                    isSacred: false,
                    associations: "A quiet month in the calendar. The regular voluntary fasts apply as in any month: Mondays and Thursdays, and the white days in the middle."),

        HJMonthPage(number: 5,
                    epithet: "The first of the dry months",
                    meaning: "From a root meaning to freeze or to harden, taken to refer to water standing frozen or to the parched ground of the dry season. Ula means the first.",
                    position: "The fifth month, opening the second pair of season-named months.",
                    isSacred: false,
                    associations: "No fixed observance. The Battle of Mu'ta, in 8 AH, is placed in this month. As with the Rabi pair, the seasonal name no longer matches the time of year."),

        HJMonthPage(number: 6,
                    epithet: "The last of the dry months",
                    meaning: "The second of the pair, named as the later or last Jumada. It also appears as Jumada al-Thaniyah, the second Jumada.",
                    position: "The sixth month, and the halfway point of the year.",
                    isSacred: false,
                    associations: "No fixed observance. It sits immediately before Rajab, so it is the last ordinary month before the run of sacred and preparatory months that leads to Ramadan."),

        HJMonthPage(number: 7,
                    epithet: "The revered month",
                    meaning: "From a root meaning to hold in awe or to revere. Rajab was treated with particular respect in pre-Islamic Arabia, when weapons were laid aside during it.",
                    position: "The seventh month, and the only sacred month that stands on its own rather than in the group of three.",
                    isSacred: true,
                    associations: "The night journey and ascent are commonly commemorated on its twenty-seventh, though the sources do not fix the date. Rajab is widely treated as the opening of the approach to Ramadan, two months later. No fast in it is obligatory."),

        HJMonthPage(number: 8,
                    epithet: "The month of scattering",
                    meaning: "From a root meaning to scatter or branch out, explained by the tribes dispersing in search of water once the sacred month of Rajab had ended.",
                    position: "The eighth month, sitting directly before Ramadan.",
                    isSacred: false,
                    associations: "Voluntary fasting is described as especially frequent in Sha'ban, short of fasting it whole. Its fifteenth night is kept in many places with extra prayer, on reports that are themselves debated. Its twenty-ninth evening carries the sighting that decides when Ramadan begins."),

        HJMonthPage(number: 9,
                    epithet: "The month of the fast",
                    meaning: "From a root meaning scorching heat or burnt ground, from the season the month originally fell in. The name is the same word used for intense summer heat.",
                    position: "The ninth month, and the one the calendar is most often consulted for.",
                    isSacred: false,
                    associations: "The fast from dawn to sunset is obligatory in it for adults who are able. It carries the night prayers, increased recitation, and the last ten nights in which Laylat al-Qadr is sought. Its start and end are both decided by sighting, so its length is twenty-nine or thirty days."),

        HJMonthPage(number: 10,
                    epithet: "The month of raising",
                    meaning: "From a root meaning to lift or raise. The usual explanation refers to camels raising their tails, a sign noted at that time of year.",
                    position: "The tenth month, opening with the festival that closes Ramadan.",
                    isSacred: false,
                    associations: "Its first day is Eid al-Fitr, on which fasting is not permitted. Six voluntary fasts kept anywhere in the rest of the month are a widespread practice. From its second day the calendar returns to ordinary time."),

        HJMonthPage(number: 11,
                    epithet: "The month of sitting",
                    meaning: "Dhu al-Qadah means the one of sitting: the month in which people sat still from fighting and from raiding, so that travel to the pilgrimage would be safe.",
                    position: "The eleventh month, and the first of the three sacred months that run consecutively into the new year.",
                    isSacred: true,
                    associations: "It carries no festival of its own, which is part of its character. Pilgrims travelling to Mecca commonly set out during it. The Treaty of Hudaybiyyah, in 6 AH, is placed in this month."),

        HJMonthPage(number: 12,
                    epithet: "The month of the pilgrimage",
                    meaning: "Dhu al-Hijjah means the one of the Hajj. The month is named for the pilgrimage that can only be performed in it.",
                    position: "The twelfth and last month of the year. In a leap year of this calendar it is the month that receives the extra day, running thirty days instead of twenty-nine.",
                    isSacred: true,
                    associations: "Its first ten days are described as the best of the year for good deeds. The ninth is the Day of Arafah, the tenth Eid al-Adha, and the eleventh to thirteenth the days of Tashriq, on which fasting is not permitted. The Hajj itself runs from the eighth to the thirteenth.")
    ]

    static func page(_ number: Int) -> HJMonthPage {
        pages[max(1, min(12, number)) - 1]
    }

    static let sacredMonthNumbers = [1, 7, 11, 12]
}
