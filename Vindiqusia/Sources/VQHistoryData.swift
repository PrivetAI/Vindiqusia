import Foundation

/// A dated event, with both reckonings and a note on how firm the date is.
struct VQHistoryEvent: Identifiable {
    let id: String
    let title: String
    /// AH year for sorting. Events before the Hijra carry a value at or below zero.
    let ahYear: Int
    /// How the AH year should read, since some entries are a span and some precede the era.
    let ahLabel: String
    let ceLabel: String
    /// True when the year is reported differently by different sources, or is a span.
    let approximate: Bool
    let detail: String

    init(_ id: String, _ title: String, ah: Int, ahLabel: String, ce: String,
         approximate: Bool = false, detail: String) {
        self.id = id
        self.title = title
        self.ahYear = ah
        self.ahLabel = ahLabel
        self.ceLabel = ce
        self.approximate = approximate
        self.detail = detail
    }

    /// 0 for anything before the Hijra, otherwise the Hijri century (1 = 1-100 AH).
    var century: Int {
        ahYear <= 0 ? 0 : (ahYear - 1) / 100 + 1
    }
}

enum VQHistoryLibrary {

    /// Only events the app is confident about. Where sources differ, the entry says so
    /// rather than picking a year and presenting it as settled.
    static let events: [VQHistoryEvent] = [

        // --------------------------------------------------- before the Hijra
        VQHistoryEvent("elephant", "The Year of the Elephant",
                       ah: -60, ahLabel: "Before the Hijra", ce: "c. 570 CE", approximate: true,
                       detail: "The year traditionally given for the birth of Muhammad in Mecca, and named for an Abyssinian expedition against the city that Arabian memory attached an elephant to. The dating is traditional rather than documentary, and modern estimates vary by several years."),

        VQHistoryEvent("first-revelation", "The first revelation",
                       ah: -13, ahLabel: "c. 12 years before the Hijra", ce: "c. 610 CE", approximate: true,
                       detail: "The opening verses of Sura al-Alaq, received in the cave of Hira outside Mecca. Public preaching followed some three years later. The precise year is inferred from the traditional chronology rather than recorded at the time."),

        VQHistoryEvent("abyssinia", "The migration to Abyssinia",
                       ah: -7, ahLabel: "c. 7 years before the Hijra", ce: "c. 615 CE", approximate: true,
                       detail: "A group of Muslims left Mecca for the Christian kingdom of Aksum to escape persecution, and were given protection there. It was the first organised departure of the community from Mecca and set the precedent for the later move to Medina."),

        VQHistoryEvent("year-sorrow", "The Year of Sorrow",
                       ah: -3, ahLabel: "c. 3 years before the Hijra", ce: "c. 619 CE", approximate: true,
                       detail: "The year in which both Khadijah, the Prophet's wife, and Abu Talib, his uncle and protector, died. The loss of Abu Talib removed the tribal protection that had made preaching in Mecca possible, and pressure on the community increased sharply."),

        // --------------------------------------------------- 1st century AH
        VQHistoryEvent("hijra", "The Hijra to Medina",
                       ah: 1, ahLabel: "1 AH", ce: "622 CE",
                       detail: "The migration from Mecca to Yathrib, afterwards called Medina, made by the Prophet and his companions. It is the event the Islamic era counts from, though the era itself was instituted later. The community that formed there was the first to govern its own affairs."),

        VQHistoryEvent("constitution", "The Constitution of Medina",
                       ah: 1, ahLabel: "1 AH", ce: "622 CE", approximate: true,
                       detail: "An agreement setting out the terms on which the migrants, the Medinan tribes and the Jewish clans of the city would live and defend it together. It is one of the earliest documents of its kind to survive in its substance. Its exact date within the first years at Medina is not certain."),

        VQHistoryEvent("qibla", "The change of the qibla",
                       ah: 2, ahLabel: "2 AH", ce: "624 CE",
                       detail: "The direction of prayer was turned from Jerusalem to the Kaaba in Mecca. The change came in the second year at Medina and is referred to directly in the Quran. It gave the young community a centre of its own."),

        VQHistoryEvent("ramadan-obligatory", "Fasting in Ramadan made obligatory",
                       ah: 2, ahLabel: "2 AH", ce: "624 CE",
                       detail: "The fast of Ramadan was prescribed in the second year after the migration. Before that, the day of Ashura had been the community's principal fast, and it became voluntary from this point. Zakat was placed on a formal footing in the same period."),

        VQHistoryEvent("badr", "The Battle of Badr",
                       ah: 2, ahLabel: "17 Ramadan 2 AH", ce: "624 CE",
                       detail: "A much smaller Muslim force met a Meccan army at the wells of Badr and defeated it. The battle is named in the Quran and became the reference point for the community's early survival. It is dated to the seventeenth of Ramadan."),

        VQHistoryEvent("uhud", "The Battle of Uhud",
                       ah: 3, ahLabel: "3 AH", ce: "625 CE",
                       detail: "A Meccan force returned the following year and inflicted a serious reverse on the Muslims outside Medina, at the hill of Uhud. The Prophet's uncle Hamza was among those killed. The setback is discussed at length in the Quran, largely as a lesson in discipline."),

        VQHistoryEvent("trench", "The Battle of the Trench",
                       ah: 5, ahLabel: "5 AH", ce: "627 CE",
                       detail: "A coalition besieged Medina, which had been fortified with a trench dug across its exposed side on the advice of Salman al-Farisi. The siege failed without a general engagement. It was the last serious attempt by Mecca to destroy the community by force."),

        VQHistoryEvent("hudaybiyyah", "The Treaty of Hudaybiyyah",
                       ah: 6, ahLabel: "Dhu al-Qadah 6 AH", ce: "628 CE",
                       detail: "A ten-year truce agreed outside Mecca on terms that looked unfavourable at the time, including turning back from the pilgrimage that year. In practice it opened the city and the surrounding tribes to contact, and the community grew rapidly under it. The Quran calls it a clear opening."),

        VQHistoryEvent("khaybar", "The taking of Khaybar",
                       ah: 7, ahLabel: "7 AH", ce: "628 CE",
                       detail: "The fortified oasis of Khaybar, north of Medina, was taken after a siege. Its inhabitants stayed on to work the land under an arrangement that gave a share of the produce to Medina. The settlement became a model for later terms offered to conquered agricultural districts."),

        VQHistoryEvent("mutah", "The Battle of Mu'ta",
                       ah: 8, ahLabel: "Jumada al-Ula 8 AH", ce: "629 CE",
                       detail: "The first engagement with Byzantine forces, fought east of the Jordan. The Muslim force was heavily outnumbered and withdrew after its commanders were killed. It marked the beginning of contact with the empire to the north."),

        VQHistoryEvent("mecca", "The conquest of Mecca",
                       ah: 8, ahLabel: "Ramadan 8 AH", ce: "630 CE",
                       detail: "Mecca was entered with almost no fighting after the truce of Hudaybiyyah broke down. A general amnesty was declared and the idols around the Kaaba were removed. The city's leadership accepted the new order rather than resisting it."),

        VQHistoryEvent("hunayn", "The Battle of Hunayn",
                       ah: 8, ahLabel: "Shawwal 8 AH", ce: "630 CE",
                       detail: "Fought in a valley near Ta'if against tribal confederations who had not accepted the fall of Mecca. An initial ambush scattered the Muslim force before it regrouped and won. The battle is named in the Quran."),

        VQHistoryEvent("tabuk", "The expedition to Tabuk",
                       ah: 9, ahLabel: "Rajab 9 AH", ce: "630 CE",
                       detail: "A long march north in high summer, undertaken on reports of a Byzantine build-up that did not materialise. No battle followed, but agreements were made with several frontier communities. It was the last expedition the Prophet led in person."),

        VQHistoryEvent("farewell", "The Farewell Pilgrimage",
                       ah: 10, ahLabel: "Dhu al-Hijjah 10 AH", ce: "632 CE",
                       detail: "The Prophet's only complete Hajj, performed with a very large gathering, and the occasion of the sermon delivered at Arafah. The rites as performed then became the pattern for the pilgrimage ever since. It took place three months before his death."),

        VQHistoryEvent("prophet-death", "The death of the Prophet",
                       ah: 11, ahLabel: "Rabi al-Awwal 11 AH", ce: "632 CE",
                       detail: "Muhammad died at Medina after a short illness, and was buried in the room of his wife Aisha. The question of who should lead the community was settled within days, in favour of Abu Bakr, but the manner of that decision became the first and deepest division in Islamic history."),

        VQHistoryEvent("abubakr", "Abu Bakr becomes caliph",
                       ah: 11, ahLabel: "11 AH", ce: "632 CE",
                       detail: "The first of the caliphs the Sunni tradition calls rightly guided, chosen at Saqifa immediately after the Prophet's death. His two years were spent holding the Arabian tribes together through the wars of apostasy. He also ordered the first collection of the Quran into a single copy."),

        VQHistoryEvent("ridda", "The Ridda wars",
                       ah: 11, ahLabel: "11-12 AH", ce: "632-633 CE", approximate: true,
                       detail: "A series of campaigns against Arabian tribes that renounced their agreements with Medina after the Prophet's death. They ended with the peninsula reunited under the caliphate. The heavy losses among those who had memorised the Quran prompted the first written collection."),

        VQHistoryEvent("umar", "Umar becomes caliph",
                       ah: 13, ahLabel: "13 AH", ce: "634 CE",
                       detail: "Abu Bakr nominated Umar ibn al-Khattab before his death, and the community accepted him. His ten years saw the conquest of Syria, Egypt and much of Iran, and the building of an administration to hold them. The garrison cities of Kufa and Basra were founded under him."),

        VQHistoryEvent("yarmuk", "The Battle of Yarmuk",
                       ah: 15, ahLabel: "Rajab 15 AH", ce: "636 CE",
                       detail: "A decisive engagement against a Byzantine army on the Yarmuk river, in what is now the Jordan-Syria border country. Byzantine authority in Syria did not recover from it. The province passed to the caliphate within a few years."),

        VQHistoryEvent("qadisiyyah", "The Battle of al-Qadisiyyah",
                       ah: 15, ahLabel: "15 or 16 AH", ce: "636-637 CE", approximate: true,
                       detail: "The battle that broke the Sasanian field army in Iraq, fought near Kufa over several days. The sources give the year variously, which is why it is shown here as a range. The Sasanian capital at Ctesiphon fell soon after."),

        VQHistoryEvent("jerusalem", "Jerusalem enters Muslim rule",
                       ah: 17, ahLabel: "c. 16-17 AH", ce: "c. 637-638 CE", approximate: true,
                       detail: "The city surrendered on terms, and the tradition holds that Umar came in person to receive it and guaranteed the safety of its inhabitants and churches. The exact year is reported differently in different sources. Jerusalem became the third city of Muslim pilgrimage after Mecca and Medina."),

        VQHistoryEvent("calendar", "The Hijri calendar instituted",
                       ah: 17, ahLabel: "c. 16-17 AH", ce: "c. 638 CE", approximate: true,
                       detail: "Umar's administration needed a common dating system for its correspondence and settled on counting years from the Hijra, beginning with the Muharram that preceded it. The months and their names were already in use; what was new was the era. The calendar this app computes is the arithmetic form of that scheme."),

        VQHistoryEvent("nahavand", "The Battle of Nahavand",
                       ah: 21, ahLabel: "21 AH", ce: "642 CE",
                       detail: "The last large Sasanian army was defeated in the Zagros mountains, ending organised resistance on the Iranian plateau. Arab sources call it the victory of victories. The conquest of the eastern provinces followed over the next decade."),

        VQHistoryEvent("uthman", "Uthman becomes caliph",
                       ah: 23, ahLabel: "23 AH", ce: "644 CE",
                       detail: "Umar was killed by a slave in Medina, and a council of six chose Uthman ibn Affan to succeed him. His twelve years saw further expansion and the standardisation of the Quranic text. Discontent in the garrison cities grew steadily in the second half of his rule."),

        VQHistoryEvent("mushaf", "The standard codex of the Quran",
                       ah: 30, ahLabel: "c. 25-30 AH", ce: "c. 645-650 CE", approximate: true,
                       detail: "Uthman had a committee produce an authoritative written text from the collection made under Abu Bakr, and sent copies to the main garrison cities with instructions that competing copies be withdrawn. The purpose was to stop disputes over recitation among troops from different regions. The consonantal text in use today descends from this."),

        VQHistoryEvent("ali", "Ali becomes caliph",
                       ah: 35, ahLabel: "35 AH", ce: "656 CE",
                       detail: "Uthman was killed by rebels in Medina and Ali ibn Abi Talib was acclaimed in his place. His rule was contested from the start by those who demanded that the killing be avenged first. The dispute became the first civil war."),

        VQHistoryEvent("camel", "The Battle of the Camel",
                       ah: 36, ahLabel: "36 AH", ce: "656 CE",
                       detail: "Fought outside Basra between Ali's forces and an opposition led by Talha, al-Zubayr and Aisha. It is named for the camel Aisha observed the battle from. It was the first time Muslims met each other in a pitched battle."),

        VQHistoryEvent("siffin", "The Battle of Siffin",
                       ah: 37, ahLabel: "Safar 37 AH", ce: "657 CE",
                       detail: "A long confrontation on the upper Euphrates between Ali and Mu'awiya, the governor of Syria. It ended not in a decision but in an agreement to arbitrate. That agreement split Ali's own following."),

        VQHistoryEvent("nahrawan", "The Battle of Nahrawan",
                       ah: 38, ahLabel: "38 AH", ce: "658 CE",
                       detail: "Fought against the Kharijites, the group that had left Ali's camp in protest at the arbitration after Siffin. Their movement survived the defeat and remained a force for centuries. Ali was killed by one of them two years later."),

        VQHistoryEvent("ali-death", "The death of Ali",
                       ah: 40, ahLabel: "Ramadan 40 AH", ce: "661 CE",
                       detail: "Ali was struck down in the mosque at Kufa by a Kharijite. His son Hasan was acclaimed but came to terms with Mu'awiya within months. The period the Sunni tradition calls the rightly guided caliphate ends here."),

        VQHistoryEvent("umayyad", "The Umayyad caliphate begins",
                       ah: 41, ahLabel: "41 AH", ce: "661 CE",
                       detail: "Mu'awiya ibn Abi Sufyan became caliph and moved the capital from Kufa to Damascus. Succession became hereditary under him, which was itself a major change. The Umayyads held the caliphate for close to ninety years."),

        VQHistoryEvent("karbala", "Karbala",
                       ah: 61, ahLabel: "10 Muharram 61 AH", ce: "680 CE",
                       detail: "Husayn ibn Ali, the Prophet's grandson, was killed with most of his family and followers by an Umayyad force in southern Iraq. The event is central to Shia identity and is commemorated every Ashura. It hardened the division between Shia and Sunni into a permanent one."),

        VQHistoryEvent("abdalmalik", "Abd al-Malik and the second civil war",
                       ah: 65, ahLabel: "65-73 AH", ce: "685-692 CE", approximate: true,
                       detail: "Abd al-Malik came to power during a war in which Ibn al-Zubayr held Mecca and much of the east as a rival caliph. The reunification took seven years. The reign that followed reorganised the state more thoroughly than any since Umar."),

        VQHistoryEvent("dome", "The Dome of the Rock completed",
                       ah: 72, ahLabel: "72 AH", ce: "691-692 CE",
                       detail: "Built by Abd al-Malik on the Temple Mount in Jerusalem, and dated by an inscription inside it. It is the oldest surviving Islamic monument, and its inscriptions are among the earliest datable Quranic texts in existence. The building is a shrine rather than a congregational mosque."),

        VQHistoryEvent("coinage", "Arabic coinage and administration",
                       ah: 77, ahLabel: "c. 77 AH", ce: "c. 696 CE", approximate: true,
                       detail: "Abd al-Malik replaced the inherited Byzantine and Sasanian coin types with a purely epigraphic Islamic coinage bearing no images, and made Arabic the language of the government registers. It was the point at which the caliphate stopped running on the machinery of the empires it had replaced. The dinar and dirham types set then lasted for centuries."),

        VQHistoryEvent("iberia", "The crossing into Iberia",
                       ah: 92, ahLabel: "92 AH", ce: "711 CE",
                       detail: "A force under Tariq ibn Ziyad crossed from North Africa and defeated the Visigothic king Roderic. Most of the peninsula was under Muslim control within a few years. Gibraltar takes its name from Tariq."),

        VQHistoryEvent("sind", "Expansion into Sind and Transoxiana",
                       ah: 93, ahLabel: "c. 93-96 AH", ce: "c. 712-715 CE", approximate: true,
                       detail: "Campaigns in the lower Indus valley and across the Oxus extended the caliphate to its eastern limits in the same years as the advance into Iberia. Both frontiers were reached under al-Walid I. The dates of individual campaigns vary between sources."),

        // --------------------------------------------------- 2nd century AH
        VQHistoryEvent("umar2", "The caliphate of Umar ibn Abd al-Aziz",
                       ah: 99, ahLabel: "99-101 AH", ce: "717-720 CE",
                       detail: "A short reign remembered for reversing the fiscal discrimination against non-Arab converts and for a deliberately austere court. Later tradition places him alongside the first four caliphs. He also ordered one of the earliest systematic efforts to write down hadith."),

        VQHistoryEvent("tours", "The advance into Gaul halted",
                       ah: 114, ahLabel: "114 AH", ce: "732 CE",
                       detail: "A raiding army pushing north from Iberia was defeated between Tours and Poitiers by Frankish forces under Charles Martel. Muslim expansion into western Europe went no further, though raids continued for decades. The battle's later reputation is larger than its size."),

        VQHistoryEvent("abbasid", "The Abbasid revolution",
                       ah: 132, ahLabel: "132 AH", ce: "750 CE",
                       detail: "A movement that began in Khurasan overthrew the Umayyads and installed the Abbasid family in the caliphate. The centre of gravity moved from Syria to Iraq, and from Arab dominance to a more mixed governing class. One Umayyad prince escaped to Iberia."),

        VQHistoryEvent("cordoba", "The emirate of Cordoba",
                       ah: 138, ahLabel: "138 AH", ce: "756 CE",
                       detail: "Abd al-Rahman I, the surviving Umayyad, established an independent state in the Iberian peninsula with its capital at Cordoba. It was the first serious fracture in the political unity of the caliphate. His descendants declared themselves caliphs in the tenth century."),

        VQHistoryEvent("baghdad", "Baghdad founded",
                       ah: 145, ahLabel: "145 AH", ce: "762 CE",
                       detail: "Al-Mansur laid out a new round city on the Tigris as the Abbasid capital. Within a century it was among the largest cities in the world and the centre of a translation movement that preserved and extended Greek science. It remained the seat of the caliphate for five hundred years."),

        VQHistoryEvent("abuhanifa", "Death of Abu Hanifa",
                       ah: 150, ahLabel: "150 AH", ce: "767 CE",
                       detail: "The jurist of Kufa whose students founded the Hanafi school, the most widely followed of the four Sunni schools of law. His method gave considerable weight to reasoned analogy. He died in Baghdad, having refused judicial office."),

        VQHistoryEvent("malik", "Death of Malik ibn Anas",
                       ah: 179, ahLabel: "179 AH", ce: "795 CE",
                       detail: "The jurist of Medina and author of the Muwatta, the earliest surviving law book in Islam. The Maliki school takes his name and became dominant in North and West Africa. His approach gave particular authority to the settled practice of Medina."),

        VQHistoryEvent("harun", "The caliphate of Harun al-Rashid",
                       ah: 170, ahLabel: "170-193 AH", ce: "786-809 CE",
                       detail: "The reign later remembered as the height of Abbasid wealth and reach, and the one the Thousand and One Nights attached itself to. The civil war between his sons after his death did lasting damage. The translation movement in Baghdad gathered pace under him and his successors."),

        VQHistoryEvent("translation", "The translation movement",
                       ah: 200, ahLabel: "2nd-3rd centuries AH", ce: "8th-9th centuries CE", approximate: true,
                       detail: "Greek, Persian and Indian works in medicine, mathematics, astronomy and philosophy were translated into Arabic on a large scale, largely in Baghdad and largely with state backing. Much of Greek science survives only because of it. The work spanned generations rather than a single reign or institution."),

        // --------------------------------------------------- 3rd century AH
        VQHistoryEvent("shafii", "Death of al-Shafi'i",
                       ah: 204, ahLabel: "204 AH", ce: "820 CE",
                       detail: "The jurist who set out a systematic theory of the sources of law, ranking Quran, sunna, consensus and analogy. His Risala is the foundational text of Islamic legal theory. The Shafi'i school takes his name and spread widely in Egypt, East Africa and Southeast Asia."),

        VQHistoryEvent("khwarizmi", "Al-Khwarizmi",
                       ah: 232, ahLabel: "d. c. 232-235 AH", ce: "d. c. 847-850 CE", approximate: true,
                       detail: "A mathematician and astronomer working in Baghdad whose book on restoring and balancing gave the word algebra, and whose name, latinised, gave the word algorithm. He also helped introduce the Indian decimal numerals into Arabic use. His dates of birth and death are only approximately known."),

        VQHistoryEvent("ibnhanbal", "Death of Ahmad ibn Hanbal",
                       ah: 241, ahLabel: "241 AH", ce: "855 CE",
                       detail: "A traditionist and jurist who compiled an enormous collection of hadith and gave his name to the fourth Sunni school of law. He was imprisoned for refusing to accept a doctrine imposed by the caliph al-Ma'mun. That episode made him a symbol of resistance to state interference in creed."),

        VQHistoryEvent("bukhari", "Death of al-Bukhari",
                       ah: 256, ahLabel: "256 AH", ce: "870 CE",
                       detail: "The compiler of the Sahih, the hadith collection Sunni Muslims rank highest after the Quran. He is said to have sifted a very large body of reports down to a few thousand on strict criteria of transmission. He was born in Bukhara and died near Samarkand."),

        VQHistoryEvent("muslim", "Death of Muslim ibn al-Hajjaj",
                       ah: 261, ahLabel: "261 AH", ce: "875 CE",
                       detail: "Compiler of the second of the two collections known as the Sahihayn, arranged more systematically than al-Bukhari's. He was a student of al-Bukhari among others. The two collections together form the core of Sunni hadith scholarship."),

        // --------------------------------------------------- 4th century AH
        VQHistoryEvent("fatimid", "The Fatimid caliphate founded",
                       ah: 297, ahLabel: "297 AH", ce: "909 CE",
                       detail: "An Ismaili Shia dynasty took power in Ifriqiya and claimed the caliphate in opposition to Baghdad. It conquered Egypt sixty years later and founded Cairo as its capital. For a time three rival caliphates existed at once, in Baghdad, Cairo and Cordoba."),

        VQHistoryEvent("tabari", "Death of al-Tabari",
                       ah: 310, ahLabel: "310 AH", ce: "923 CE",
                       detail: "Historian and Quranic commentator whose history of the world down to his own time is the single most important narrative source for the first three centuries of Islam. His commentary on the Quran is equally foundational. He preserved the reports of earlier writers whose own books are lost."),

        VQHistoryEvent("azhar", "Al-Azhar founded in Cairo",
                       ah: 359, ahLabel: "c. 359-361 AH", ce: "c. 970-972 CE", approximate: true,
                       detail: "Built by the Fatimids as a congregational mosque, and developed into a teaching institution within a few years. It later passed to Sunni control and has taught continuously since. Its foundation and its opening as a place of study are dated slightly differently."),

        // --------------------------------------------------- 5th century AH
        VQHistoryEvent("ibnsina", "Death of Ibn Sina",
                       ah: 428, ahLabel: "428 AH", ce: "1037 CE",
                       detail: "Physician and philosopher, known in Latin Europe as Avicenna. His Canon of Medicine was a standard medical text on both sides of the Mediterranean for centuries, and his metaphysics shaped philosophy in Arabic, Hebrew and Latin alike. He worked across Iran under a series of local rulers."),

        VQHistoryEvent("manzikert", "The Battle of Manzikert",
                       ah: 463, ahLabel: "463 AH", ce: "1071 CE",
                       detail: "The Seljuk sultan Alp Arslan defeated a Byzantine army in eastern Anatolia and captured the emperor. The defeat opened Anatolia to Turkish settlement. It is a large part of why the Byzantine appeal for western help, and then the crusades, followed."),

        VQHistoryEvent("crusade", "The First Crusade takes Jerusalem",
                       ah: 492, ahLabel: "492 AH", ce: "1099 CE",
                       detail: "A western European expedition captured Jerusalem after a siege and established a kingdom there. The initial Muslim response was fragmented, and the crusader states survived for most of two centuries. The city changed hands again in 583 AH."),

        VQHistoryEvent("ghazali", "Death of al-Ghazali",
                       ah: 505, ahLabel: "505 AH", ce: "1111 CE",
                       detail: "A theologian and jurist who left a leading chair in Baghdad for years of withdrawal, then wrote the Revival of the Religious Sciences, which reconciled legal scholarship with the inner life. His critique of the philosophers reshaped the debate for centuries. He is among the most widely read authors in Islamic thought."),

        // --------------------------------------------------- 6th century AH onward
        VQHistoryEvent("hattin", "Salah al-Din retakes Jerusalem",
                       ah: 583, ahLabel: "583 AH", ce: "1187 CE",
                       detail: "After destroying the crusader field army at Hattin, Salah al-Din took Jerusalem on terms that spared the population. The city had been held by the crusaders for eighty-eight years. His conduct at the surrender was noted even by his opponents."),

        VQHistoryEvent("ibnrushd", "Death of Ibn Rushd",
                       ah: 595, ahLabel: "595 AH", ce: "1198 CE",
                       detail: "Judge, physician and philosopher of Cordoba, known in Latin as Averroes. His commentaries on Aristotle were translated into Latin and Hebrew and became central to European scholastic thought. He answered al-Ghazali's critique of philosophy directly."),

        VQHistoryEvent("baghdad-fall", "The Mongols sack Baghdad",
                       ah: 656, ahLabel: "656 AH", ce: "1258 CE",
                       detail: "Hulagu's army took the city, killed the last Abbasid caliph of Baghdad and destroyed much of it. The caliphate as a functioning institution ended there, though a shadow line continued in Cairo. The loss of libraries and irrigation works was not made good."),

        VQHistoryEvent("aynjalut", "The Battle of Ayn Jalut",
                       ah: 658, ahLabel: "658 AH", ce: "1260 CE",
                       detail: "A Mamluk army from Egypt defeated a Mongol force in Galilee, the first significant check to the Mongol advance westward. Syria and Egypt were kept out of Mongol hands. The Mamluk sultanate went on to rule both for two and a half centuries."),

        VQHistoryEvent("ibnbattuta", "Ibn Battuta sets out",
                       ah: 725, ahLabel: "725 AH", ce: "1325 CE",
                       detail: "A young jurist left Tangier for the pilgrimage and did not return for nearly thirty years, travelling across Africa, Asia and as far as China. The account dictated on his return is the widest first-hand description of the fourteenth-century world by any single traveller. Parts of it are borrowed from earlier writers, which scholars have long noted."),

        VQHistoryEvent("muqaddimah", "Ibn Khaldun completes the Muqaddimah",
                       ah: 779, ahLabel: "779 AH", ce: "1377 CE",
                       detail: "The introduction to his universal history set out a theory of how states rise and decay through the loosening of group solidarity. It treats history as a subject with causes rather than a chain of anecdotes, and is often called the earliest work of social science. He died in Cairo in 808 AH."),

        VQHistoryEvent("constantinople", "The fall of Constantinople",
                       ah: 857, ahLabel: "857 AH", ce: "1453 CE",
                       detail: "Mehmed II took the city after a seven-week siege, ending the Byzantine empire. The Ottomans made it their capital and it remained so until the empire's end. The siege was among the first in which heavy gunpowder artillery was decisive."),

        VQHistoryEvent("granada", "The fall of Granada",
                       ah: 897, ahLabel: "897 AH", ce: "1492 CE",
                       detail: "The last Muslim state in the Iberian peninsula surrendered to Castile and Aragon, ending nearly eight centuries of Muslim rule there. Guarantees given at the surrender were withdrawn within a decade. Expulsions of Muslims and Jews followed."),

        VQHistoryEvent("cairo1517", "The Ottomans take Cairo",
                       ah: 923, ahLabel: "922-923 AH", ce: "1517 CE",
                       detail: "Selim I defeated the Mamluks and annexed Egypt, Syria and the Hijaz. Custody of Mecca and Medina passed to the Ottoman sultans, who held it until the twentieth century. It made the Ottoman state the leading Muslim power for the next three hundred years.")
    ]

    /// Centuries present in the data, for the filter row. 0 stands for events before the era.
    static var centuries: [Int] {
        Array(Set(events.map { $0.century })).sorted()
    }

    static func centuryLabel(_ century: Int) -> String {
        if century == 0 { return "Before the Hijra" }
        return "\(VQFormatter.ordinal(century)) century AH"
    }

    static func events(inCentury century: Int) -> [VQHistoryEvent] {
        events.filter { $0.century == century }
    }

    static var sortedEvents: [VQHistoryEvent] {
        events.sorted { $0.ahYear < $1.ahYear }
    }
}
