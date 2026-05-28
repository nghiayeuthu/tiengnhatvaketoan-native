import Foundation

struct StudyDictionaryDocument: Decodable {
    let vocabulary: [VocabularyEntry]
    let grammar: [GrammarEntry]
    let hanViet: [String: String]
}

struct VocabularyEntry: Decodable, Identifiable, Hashable {
    let word: String
    let reading: String
    let meaning: String
    let level: String

    var id: String { "\(level)-\(word)-\(reading)-\(meaning)" }

    static let supplemental: [VocabularyEntry] = [
        VocabularyEntry(word: "深刻", reading: "しんこく", meaning: "nghiêm trọng, sâu sắc", level: "N2"),
        VocabularyEntry(word: "思わぬ", reading: "おもわぬ", meaning: "không ngờ tới, bất ngờ", level: "N2"),
        VocabularyEntry(word: "潜む", reading: "ひそむ", meaning: "ẩn nấp; tiềm ẩn, ẩn chứa", level: "N1"),
        VocabularyEntry(word: "卓越", reading: "たくえつ", meaning: "vượt trội, xuất sắc", level: "N1"),
        VocabularyEntry(word: "芳しい", reading: "かんばしい", meaning: "tốt, thuận lợi; thường dùng dạng phủ định 芳しくない = không tốt", level: "N1"),
        VocabularyEntry(word: "管轄", reading: "かんかつ", meaning: "thẩm quyền quản lý, phạm vi phụ trách", level: "N1"),
        VocabularyEntry(word: "一環", reading: "いっかん", meaning: "một phần trong chuỗi/hoạt động chung", level: "N1"),
        VocabularyEntry(word: "前半", reading: "ぜんはん", meaning: "nửa đầu, hiệp đầu", level: "N2"),
        VocabularyEntry(word: "後半", reading: "こうはん", meaning: "nửa sau, hiệp sau", level: "N2"),
        VocabularyEntry(word: "逆転", reading: "ぎゃくてん", meaning: "lội ngược dòng, đảo ngược tình thế", level: "N2"),
        VocabularyEntry(word: "リード", reading: "リード", meaning: "dẫn trước, dẫn điểm", level: "N2"),
        VocabularyEntry(word: "互角", reading: "ごかく", meaning: "ngang tài ngang sức", level: "N1"),
        VocabularyEntry(word: "若手", reading: "わかて", meaning: "người trẻ, lớp trẻ có triển vọng", level: "N2"),
        VocabularyEntry(word: "実力", reading: "じつりょく", meaning: "thực lực, năng lực thật", level: "N2"),
        VocabularyEntry(word: "割り当てる", reading: "わりあてる", meaning: "phân công, phân bổ, giao cho", level: "N2"),
        VocabularyEntry(word: "周到", reading: "しゅうとう", meaning: "chu đáo, chuẩn bị kỹ lưỡng", level: "N1"),
        VocabularyEntry(word: "臨む", reading: "のぞむ", meaning: "tham dự, bước vào; đối mặt với", level: "N1"),
        VocabularyEntry(word: "ひとまず", reading: "ひとまず", meaning: "tạm thời, trước hết", level: "N2"),
        VocabularyEntry(word: "むしゃくしゃ", reading: "むしゃくしゃ", meaning: "bực bội, khó chịu trong lòng", level: "N2"),
        VocabularyEntry(word: "誇張", reading: "こちょう", meaning: "phóng đại, nói quá", level: "N1"),
        VocabularyEntry(word: "ひそか", reading: "ひそか", meaning: "âm thầm, bí mật, kín đáo", level: "N1"),
        VocabularyEntry(word: "試練", reading: "しれん", meaning: "thử thách, gian nan", level: "N1"),
        VocabularyEntry(word: "苦難", reading: "くなん", meaning: "khó khăn, gian khổ", level: "N1"),
        VocabularyEntry(word: "うろたえる", reading: "うろたえる", meaning: "lúng túng, hoảng hốt, mất bình tĩnh", level: "N1"),
        VocabularyEntry(word: "慌てる", reading: "あわてる", meaning: "vội vàng, hoảng hốt", level: "N2"),
        VocabularyEntry(word: "当面", reading: "とうめん", meaning: "trước mắt, trong thời gian hiện tại", level: "N2"),
        VocabularyEntry(word: "しばらく", reading: "しばらく", meaning: "một lúc, một thời gian", level: "N3"),
        VocabularyEntry(word: "憩い", reading: "いこい", meaning: "sự nghỉ ngơi, thư giãn; nơi nghỉ chân", level: "N1"),
        VocabularyEntry(word: "憩う", reading: "いこう", meaning: "nghỉ ngơi, thư giãn", level: "N1"),
        VocabularyEntry(word: "自前", reading: "じまえ", meaning: "tự mình lo; đồ của mình, tự có", level: "N1"),
        VocabularyEntry(word: "衣装", reading: "いしょう", meaning: "trang phục, phục trang", level: "N2"),
        VocabularyEntry(word: "壊す", reading: "こわす", meaning: "phá, làm hỏng", level: "N3"),
        VocabularyEntry(word: "壊れる", reading: "こわれる", meaning: "bị hỏng, bị phá", level: "N3"),
        VocabularyEntry(word: "ルーズ", reading: "ルーズ", meaning: "cẩu thả, lỏng lẻo, không chặt chẽ", level: "N2"),
        VocabularyEntry(word: "なじむ", reading: "なじむ", meaning: "quen, hòa nhập, hợp với", level: "N2"),
        VocabularyEntry(word: "煩わしい", reading: "わずらわしい", meaning: "phiền phức, rắc rối", level: "N1"),
        VocabularyEntry(word: "嫌味", reading: "いやみ", meaning: "lời mỉa mai; vẻ khó ưa", level: "N2"),
        VocabularyEntry(word: "伴奏", reading: "ばんそう", meaning: "đệm nhạc", level: "N1"),
        VocabularyEntry(word: "練る", reading: "ねる", meaning: "trau chuốt, nghiền ngẫm, lập kỹ", level: "N2"),
        VocabularyEntry(word: "まばら", reading: "まばら", meaning: "thưa thớt, lác đác", level: "N1"),
        VocabularyEntry(word: "どんより", reading: "どんより", meaning: "u ám, nặng nề, âm u", level: "N2"),
        VocabularyEntry(word: "捗る", reading: "はかどる", meaning: "tiến triển thuận lợi, trôi chảy", level: "N1"),
        VocabularyEntry(word: "やむを得ず", reading: "やむをえず", meaning: "bất đắc dĩ, không còn cách nào khác", level: "N2"),
        VocabularyEntry(word: "細心", reading: "さいしん", meaning: "hết sức cẩn thận, tỉ mỉ", level: "N1"),
        VocabularyEntry(word: "めきめき", reading: "めきめき", meaning: "nhanh chóng, rõ rệt", level: "N1"),
        VocabularyEntry(word: "利益", reading: "りえき", meaning: "lợi ích, lợi nhuận", level: "N3"),
        VocabularyEntry(word: "目論む", reading: "もくろむ", meaning: "mưu tính, lên kế hoạch", level: "N1"),
        VocabularyEntry(word: "にわかには", reading: "にわかには", meaning: "khó mà ngay lập tức, không dễ gì", level: "N1"),
        VocabularyEntry(word: "シビア", reading: "シビア", meaning: "nghiêm khắc, khắt khe", level: "N1"),
        VocabularyEntry(word: "鈍る", reading: "にぶる", meaning: "cùn đi; suy giảm, chậm lại", level: "N2"),
        VocabularyEntry(word: "歴然", reading: "れきぜん", meaning: "rõ ràng, hiển nhiên", level: "N1"),
        VocabularyEntry(word: "おのずと", reading: "おのずと", meaning: "tự nhiên, tự khắc", level: "N1"),
        VocabularyEntry(word: "枠", reading: "わく", meaning: "khung, khuôn khổ, phạm vi", level: "N2"),
        VocabularyEntry(word: "スケール", reading: "スケール", meaning: "quy mô, tầm cỡ", level: "N2"),
        VocabularyEntry(word: "しきりに", reading: "しきりに", meaning: "liên tục, nhiều lần, không ngừng", level: "N2"),
        VocabularyEntry(word: "けなす", reading: "けなす", meaning: "chê bai, nói xấu", level: "N1"),
        VocabularyEntry(word: "おっくう", reading: "おっくう", meaning: "ngại, thấy phiền, không muốn làm", level: "N1"),
        VocabularyEntry(word: "跡地", reading: "あとち", meaning: "khu đất sau khi dỡ/chuyển đi", level: "N1"),
        VocabularyEntry(word: "あらかじめ", reading: "あらかじめ", meaning: "trước, sẵn, từ trước", level: "N2"),
        VocabularyEntry(word: "抜群", reading: "ばつぐん", meaning: "vượt trội, xuất sắc", level: "N1"),
        VocabularyEntry(word: "バックアップ", reading: "バックアップ", meaning: "hỗ trợ; sao lưu", level: "N2"),
        VocabularyEntry(word: "おおむね", reading: "おおむね", meaning: "nhìn chung, đại khái", level: "N1"),
        VocabularyEntry(word: "ことごとく", reading: "ことごとく", meaning: "toàn bộ, hết thảy", level: "N1"),
        VocabularyEntry(word: "裏づけ", reading: "うらづけ", meaning: "căn cứ, bằng chứng hỗ trợ", level: "N1"),
        VocabularyEntry(word: "術", reading: "すべ", meaning: "cách, phương kế", level: "N1"),
        VocabularyEntry(word: "急かす", reading: "せかす", meaning: "thúc giục", level: "N1"),
        VocabularyEntry(word: "ストレート", reading: "ストレート", meaning: "thẳng thắn, trực tiếp", level: "N2"),
        VocabularyEntry(word: "気掛かり", reading: "きがかり", meaning: "lo lắng, bận tâm", level: "N2"),
        VocabularyEntry(word: "不用意", reading: "ふようい", meaning: "bất cẩn, thiếu thận trọng", level: "N1"),
        VocabularyEntry(word: "手分け", reading: "てわけ", meaning: "chia việc, phân công", level: "N2"),
        VocabularyEntry(word: "慕う", reading: "したう", meaning: "kính mến, ngưỡng mộ, yêu quý", level: "N1"),
        VocabularyEntry(word: "仕上がる", reading: "しあがる", meaning: "hoàn thành, xong xuôi", level: "N2"),
        VocabularyEntry(word: "クレーム", reading: "クレーム", meaning: "khiếu nại, phàn nàn", level: "N2"),
        VocabularyEntry(word: "今更", reading: "いまさら", meaning: "đến giờ thì..., quá muộn", level: "N2"),
        VocabularyEntry(word: "くまなく", reading: "くまなく", meaning: "khắp nơi, không bỏ sót", level: "N1"),
        VocabularyEntry(word: "ふいに", reading: "ふいに", meaning: "đột nhiên, bất chợt", level: "N2"),
        VocabularyEntry(word: "もはや", reading: "もはや", meaning: "đã/không còn... nữa", level: "N2"),
        VocabularyEntry(word: "甚だしい", reading: "はなはだしい", meaning: "quá mức, nghiêm trọng", level: "N1"),
        VocabularyEntry(word: "催す", reading: "もよおす", meaning: "tổ chức; cảm thấy", level: "N2"),
        VocabularyEntry(word: "満たない", reading: "みたない", meaning: "chưa đến, không đủ", level: "N2"),
        VocabularyEntry(word: "言い張る", reading: "いいはる", meaning: "khăng khăng, một mực nói", level: "N2"),
        VocabularyEntry(word: "人出", reading: "ひとで", meaning: "lượng người ra ngoài, đám đông", level: "N1"),
        VocabularyEntry(word: "一任", reading: "いちにん", meaning: "giao phó toàn quyền", level: "N1"),
        VocabularyEntry(word: "荷が重い", reading: "にがおもい", meaning: "quá sức, là gánh nặng", level: "N2"),
        VocabularyEntry(word: "支援", reading: "しえん", meaning: "hỗ trợ, viện trợ", level: "N2"),
        VocabularyEntry(word: "仰天", reading: "ぎょうてん", meaning: "kinh ngạc, sửng sốt", level: "N1"),
        VocabularyEntry(word: "かばう", reading: "かばう", meaning: "bảo vệ, bênh vực", level: "N2"),
        VocabularyEntry(word: "はがす", reading: "はがす", meaning: "bóc, gỡ, lột ra", level: "N2"),
        VocabularyEntry(word: "可決", reading: "かけつ", meaning: "thông qua, được phê chuẩn", level: "N1"),
        VocabularyEntry(word: "異色", reading: "いしょく", meaning: "khác thường, độc đáo", level: "N1"),
        VocabularyEntry(word: "揺らぎ", reading: "ゆらぎ", meaning: "dao động, lung lay", level: "N1"),
        VocabularyEntry(word: "耐えがたい", reading: "たえがたい", meaning: "khó chịu đựng", level: "N1"),
        VocabularyEntry(word: "稼働", reading: "かどう", meaning: "vận hành, hoạt động", level: "N1"),
        VocabularyEntry(word: "錯覚", reading: "さっかく", meaning: "ảo giác; hiểu nhầm", level: "N1"),
        VocabularyEntry(word: "殺到", reading: "さっとう", meaning: "đổ xô tới, ùn tới", level: "N1"),
        VocabularyEntry(word: "平凡", reading: "へいぼん", meaning: "bình thường, tầm thường", level: "N2"),
        VocabularyEntry(word: "ささい", reading: "ささい", meaning: "nhỏ nhặt, không đáng kể", level: "N1"),
        VocabularyEntry(word: "戸惑う", reading: "とまどう", meaning: "bối rối, lúng túng", level: "N2"),
        VocabularyEntry(word: "かねがね", reading: "かねがね", meaning: "từ lâu, trước nay", level: "N1"),
        VocabularyEntry(word: "お詫び", reading: "おわび", meaning: "lời xin lỗi", level: "N2"),
        VocabularyEntry(word: "怯える", reading: "おびえる", meaning: "sợ hãi, hoảng sợ", level: "N2"),
        VocabularyEntry(word: "非", reading: "ひ", meaning: "lỗi, sai trái, điều không đúng", level: "N1"),
        VocabularyEntry(word: "粘り強い", reading: "ねばりづよい", meaning: "kiên trì, bền bỉ", level: "N1"),
        VocabularyEntry(word: "むっとする", reading: "むっとする", meaning: "bực mình, sa sầm mặt", level: "N2"),
        VocabularyEntry(word: "真っ先", reading: "まっさき", meaning: "đầu tiên, trước hết", level: "N2"),
        VocabularyEntry(word: "うなだれる", reading: "うなだれる", meaning: "cúi gằm đầu", level: "N1"),
        VocabularyEntry(word: "言及", reading: "げんきゅう", meaning: "đề cập, nhắc tới", level: "N1"),
        VocabularyEntry(word: "速やか", reading: "すみやか", meaning: "nhanh chóng, mau lẹ", level: "N2"),
        VocabularyEntry(word: "つかの間", reading: "つかのま", meaning: "thoáng chốc, trong khoảnh khắc", level: "N1"),
        VocabularyEntry(word: "しくじる", reading: "しくじる", meaning: "thất bại, mắc lỗi", level: "N1"),
        VocabularyEntry(word: "心当たり", reading: "こころあたり", meaning: "điều nhớ ra, manh mối", level: "N1"),
        VocabularyEntry(word: "起用", reading: "きよう", meaning: "bổ nhiệm, dùng người", level: "N1"),
        VocabularyEntry(word: "多角的", reading: "たかくてき", meaning: "đa phương diện, nhiều góc độ", level: "N1"),
        VocabularyEntry(word: "薄く切る", reading: "うすくきる", meaning: "cắt mỏng, thái lát", level: "N2"),
        VocabularyEntry(word: "めいめい", reading: "めいめい", meaning: "từng người, mỗi người", level: "N1"),
        VocabularyEntry(word: "渋る", reading: "しぶる", meaning: "do dự, miễn cưỡng", level: "N1"),
        VocabularyEntry(word: "かさばる", reading: "かさばる", meaning: "cồng kềnh, chiếm chỗ", level: "N1"),
        VocabularyEntry(word: "コンパクト", reading: "コンパクト", meaning: "nhỏ gọn", level: "N2"),
        VocabularyEntry(word: "つぶやく", reading: "つぶやく", meaning: "lẩm bẩm, thì thầm một mình", level: "N2"),
        VocabularyEntry(word: "ばてる", reading: "ばてる", meaning: "kiệt sức, mệt lả", level: "N2"),
        VocabularyEntry(word: "目安", reading: "めやす", meaning: "mốc, tiêu chuẩn tham khảo", level: "N2"),
        VocabularyEntry(word: "危ぶむ", reading: "あやぶむ", meaning: "lo ngại, e rằng", level: "N1"),
        VocabularyEntry(word: "異例", reading: "いれい", meaning: "hiếm, khác thường, ngoại lệ", level: "N1"),
        VocabularyEntry(word: "ひたむき", reading: "ひたむき", meaning: "hết mình, một lòng chăm chỉ", level: "N1"),
        VocabularyEntry(word: "架空", reading: "かくう", meaning: "hư cấu, tưởng tượng", level: "N1"),
        VocabularyEntry(word: "施す", reading: "ほどこす", meaning: "thực hiện, áp dụng; ban cho", level: "N1"),
        VocabularyEntry(word: "余波", reading: "よは", meaning: "dư âm, ảnh hưởng lan ra", level: "N1"),
        VocabularyEntry(word: "寡黙", reading: "かもく", meaning: "ít nói", level: "N1"),
        VocabularyEntry(word: "ずれ込む", reading: "ずれこむ", meaning: "bị trễ, lùi sang", level: "N1"),
        VocabularyEntry(word: "ろくに", reading: "ろくに", meaning: "không đủ, chẳng mấy", level: "N2"),
        VocabularyEntry(word: "なつく", reading: "なつく", meaning: "quấn, thân thiết", level: "N2"),
        VocabularyEntry(word: "派", reading: "は", meaning: "phái, phe, nhóm", level: "N2"),
        VocabularyEntry(word: "熟知", reading: "じゅくち", meaning: "biết rõ, nắm vững", level: "N1"),
        VocabularyEntry(word: "リスク", reading: "リスク", meaning: "rủi ro", level: "N2"),
        VocabularyEntry(word: "絶賛", reading: "ぜっさん", meaning: "khen ngợi hết lời", level: "N1"),
        VocabularyEntry(word: "リタイア", reading: "リタイア", meaning: "bỏ cuộc, rút lui", level: "N2"),
        VocabularyEntry(word: "かみ合う", reading: "かみあう", meaning: "ăn khớp, khớp nhau", level: "N1"),
        VocabularyEntry(word: "閉口", reading: "へいこう", meaning: "ngán ngẩm, bó tay", level: "N1"),
        VocabularyEntry(word: "気まま", reading: "きまま", meaning: "tùy thích, tùy hứng", level: "N2"),
        VocabularyEntry(word: "調達", reading: "ちょうたつ", meaning: "thu xếp, huy động, cung ứng", level: "N1"),
        VocabularyEntry(word: "スポット", reading: "スポット", meaning: "địa điểm, điểm nổi bật", level: "N2"),
        VocabularyEntry(word: "拮抗", reading: "きっこう", meaning: "cân bằng, ngang sức", level: "N1"),
        VocabularyEntry(word: "懸念", reading: "けねん", meaning: "lo ngại, quan ngại", level: "N1"),
        VocabularyEntry(word: "不慮", reading: "ふりょ", meaning: "bất ngờ, ngoài ý muốn", level: "N1"),
        VocabularyEntry(word: "もろい", reading: "もろい", meaning: "dễ vỡ, yếu, mong manh", level: "N2"),
        VocabularyEntry(word: "快挙", reading: "かいきょ", meaning: "thành tích lớn, chiến công đáng mừng", level: "N1"),
        VocabularyEntry(word: "見返り", reading: "みかえり", meaning: "đổi lại, sự đáp lại", level: "N1"),
        VocabularyEntry(word: "辛抱", reading: "しんぼう", meaning: "nhẫn nại, chịu đựng", level: "N2"),
        VocabularyEntry(word: "足手まとい", reading: "あしでまとい", meaning: "vướng víu, gánh nặng", level: "N1"),
        VocabularyEntry(word: "委託", reading: "いたく", meaning: "ủy thác, giao phó", level: "N1"),
        VocabularyEntry(word: "すがすがしい", reading: "すがすがしい", meaning: "sảng khoái, dễ chịu", level: "N1"),
        VocabularyEntry(word: "コンスタント", reading: "コンスタント", meaning: "đều đặn, ổn định", level: "N2"),
        VocabularyEntry(word: "手腕", reading: "しゅわん", meaning: "năng lực, tài xử lý", level: "N1"),
        VocabularyEntry(word: "ロス", reading: "ロス", meaning: "mất mát, lãng phí", level: "N2"),
        VocabularyEntry(word: "目下", reading: "もっか", meaning: "hiện tại, trước mắt", level: "N1"),
        VocabularyEntry(word: "請け負う", reading: "うけおう", meaning: "nhận thầu, đảm nhận", level: "N1"),
        VocabularyEntry(word: "進呈", reading: "しんてい", meaning: "biếu, tặng", level: "N1"),
        VocabularyEntry(word: "手先", reading: "てさき", meaning: "đầu ngón tay; sự khéo tay", level: "N2"),
        VocabularyEntry(word: "加筆", reading: "かひつ", meaning: "viết thêm, bổ sung vào văn bản", level: "N1"),
        VocabularyEntry(word: "着手", reading: "ちゃくしゅ", meaning: "bắt tay vào, khởi công", level: "N1"),
        VocabularyEntry(word: "破格", reading: "はかく", meaning: "phá lệ, đặc biệt; giá rất rẻ", level: "N1"),
        VocabularyEntry(word: "まろやか", reading: "まろやか", meaning: "dịu, êm, tròn vị", level: "N1"),
        VocabularyEntry(word: "抜き打ち", reading: "ぬきうち", meaning: "bất ngờ, không báo trước", level: "N1"),
        VocabularyEntry(word: "かすれる", reading: "かすれる", meaning: "khàn; mờ, nhòe", level: "N1"),
        VocabularyEntry(word: "頑丈", reading: "がんじょう", meaning: "chắc chắn, bền, vững chãi", level: "N2"),
        VocabularyEntry(word: "行政", reading: "ぎょうせい", meaning: "hành chính, chính quyền", level: "N2"),
        VocabularyEntry(word: "携わる", reading: "たずさわる", meaning: "tham gia, làm việc trong lĩnh vực", level: "N1"),
        VocabularyEntry(word: "開花", reading: "かいか", meaning: "nở hoa; phát huy tài năng", level: "N1"),
        VocabularyEntry(word: "才能", reading: "さいのう", meaning: "tài năng", level: "N3"),
        VocabularyEntry(word: "営業", reading: "えいぎょう", meaning: "kinh doanh, bán hàng", level: "N2"),
        VocabularyEntry(word: "成績", reading: "せいせき", meaning: "thành tích, kết quả", level: "N3"),
        VocabularyEntry(word: "運用", reading: "うんよう", meaning: "vận dụng, quản lý/vận hành tiền hoặc hệ thống", level: "N1"),
        VocabularyEntry(word: "緻密", reading: "ちみつ", meaning: "tỉ mỉ, tinh vi, chặt chẽ", level: "N1"),
        VocabularyEntry(word: "迫力", reading: "はくりょく", meaning: "sức mạnh gây ấn tượng, sự lôi cuốn mạnh", level: "N2"),
        VocabularyEntry(word: "目まぐるしい", reading: "めまぐるしい", meaning: "chóng mặt, thay đổi liên tục rất nhanh", level: "N1"),
        VocabularyEntry(word: "大げさ", reading: "おおげさ", meaning: "phóng đại, khoa trương", level: "N2"),
        VocabularyEntry(word: "こっそり", reading: "こっそり", meaning: "lén lút, âm thầm, kín đáo", level: "N2"),
        VocabularyEntry(word: "山小屋", reading: "やまごや", meaning: "nhà nghỉ/lều trên núi", level: "N2"),
        VocabularyEntry(word: "雨が止む", reading: "あめがやむ", meaning: "mưa tạnh", level: "N3"),
        VocabularyEntry(word: "本番", reading: "ほんばん", meaning: "lần diễn/thi thật, thời điểm chính thức", level: "N2"),
        VocabularyEntry(word: "臨む", reading: "のぞむ", meaning: "tham dự, bước vào; đối mặt với", level: "N1"),
        VocabularyEntry(word: "若手", reading: "わかて", meaning: "người trẻ, lớp trẻ có triển vọng", level: "N2")
    ]
}

struct GrammarEntry: Decodable, Identifiable, Hashable {
    let pattern: String
    let meaning: String
    let aliases: [String]?

    var id: String { pattern }
    var searchTerms: [String] { [pattern] + (aliases ?? []) }

    static let supplemental: [GrammarEntry] = [
        GrammarEntry(pattern: "はずだ", meaning: "chắc là, lẽ ra phải; suy luận có căn cứ", aliases: ["はず", "はずです", "はずだった"]),
        GrammarEntry(pattern: "てくる", meaning: "dần trở nên; thay đổi từ trước đến nay", aliases: ["てきた", "てくる"]),
        GrammarEntry(pattern: "らしい", meaning: "có vẻ, nghe nói; suy đoán dựa trên thông tin", aliases: ["らしい", "らしく"]),
        GrammarEntry(pattern: "わけだ", meaning: "thảo nào, nghĩa là; kết luận từ lý do", aliases: ["わけ", "わけです"]),
        GrammarEntry(pattern: "わけではない", meaning: "không hẳn là, không có nghĩa là", aliases: ["わけではない", "わけじゃない"]),
        GrammarEntry(pattern: "わけにはいかない", meaning: "không thể làm vì hoàn cảnh/đạo lý không cho phép", aliases: ["わけにはいかない", "わけにもいかない"]),
        GrammarEntry(pattern: "に違いない", meaning: "chắc chắn là", aliases: ["に違いない"]),
        GrammarEntry(pattern: "かもしれない", meaning: "có thể, biết đâu", aliases: ["かもしれない"]),
        GrammarEntry(pattern: "ようだ", meaning: "có vẻ như, dường như", aliases: ["ようだ", "ようです"]),
        GrammarEntry(pattern: "べきだ", meaning: "nên, cần phải", aliases: ["べき", "べきだ", "べきではない"]),
        GrammarEntry(pattern: "というときに限って", meaning: "đúng vào lúc... thì lại; thường dùng cho việc không mong muốn", aliases: ["という時に限って", "ときに限って", "時に限って"]),
        GrammarEntry(pattern: "に限って", meaning: "chính vào/lại đúng; riêng... thì", aliases: ["に限って"])
    ]
}

@MainActor
final class StudyDictionaryStore: ObservableObject {
    @Published private(set) var vocabulary: [VocabularyEntry] = []
    @Published private(set) var grammar: [GrammarEntry] = []
    @Published private(set) var hanViet: [String: String] = [:]

    init() {
        load()
    }

    func vocabularyMatches(for question: PracticeQuestion, limit: Int = 6) -> [VocabularyEntry] {
        let haystack = studyText(for: question)
        var usedWords = Set<String>()
        let supplementalIDs = Set(VocabularyEntry.supplemental.map(\.id))
        return (VocabularyEntry.supplemental + vocabulary)
            .filter { entry in
                guard entry.word.count >= 2 || containsKanji(entry.word) else { return false }
                return matches(entry, in: haystack)
            }
            .sorted {
                if $0.word == $1.word {
                    return supplementalIDs.contains($0.id) && !supplementalIDs.contains($1.id)
                }
                if $0.word.count == $1.word.count { return $0.level < $1.level }
                return $0.word.count > $1.word.count
            }
            .filter { entry in
                if usedWords.contains(entry.word) { return false }
                usedWords.insert(entry.word)
                return true
            }
            .prefix(limit)
            .map { $0 }
    }

    func grammarMatches(for question: PracticeQuestion, limit: Int = 4) -> [GrammarEntry] {
        let haystack = studyText(for: question) + "\n" + (question.explanation ?? "")
        var usedPatterns = Set<String>()
        return (grammar + GrammarEntry.supplemental)
            .filter { entry in
                entry.searchTerms.contains { term in
                    let normalized = term.replacingOccurrences(of: "〜", with: "")
                    return normalized.count >= 2 && haystack.contains(normalized)
                }
            }
            .filter { entry in
                if usedPatterns.contains(entry.pattern) { return false }
                usedPatterns.insert(entry.pattern)
                return true
            }
            .prefix(limit)
            .map { $0 }
    }

    func hanVietText(for word: String) -> String? {
        let values = word.map { String($0) }.compactMap { hanViet[$0] }
        return values.isEmpty ? nil : values.joined(separator: " ")
    }

    func note(for entry: VocabularyEntry) -> String {
        let pronunciation = [entry.reading.nonEmpty, hanVietText(for: entry.word)]
            .compactMap { $0 }
            .joined(separator: ", ")
        let readingPart = pronunciation.isEmpty ? "" : "（\(pronunciation)）"
        return "\(entry.word)\(readingPart) = \(entry.meaning)"
    }

    func matches(_ entry: VocabularyEntry, in text: String) -> Bool {
        surfaceForms(for: entry.word).contains { text.contains($0) }
            || surfaceForms(for: entry.reading).contains { text.contains($0) }
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "StudyDictionary", withExtension: "json") else {
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let document = try JSONDecoder().decode(StudyDictionaryDocument.self, from: data)
            vocabulary = document.vocabulary
            grammar = document.grammar
            hanViet = document.hanViet
        } catch {
            vocabulary = []
            grammar = []
            hanViet = [:]
        }
    }

    private func studyText(for question: PracticeQuestion) -> String {
        [
            question.text,
            question.passage ?? "",
            question.options.joined(separator: "\n"),
            question.answerText ?? "",
            question.correctAnswer.flatMap { index in
                question.options.indices.contains(index - 1) ? question.options[index - 1] : nil
            } ?? ""
        ].joined(separator: "\n")
    }

    private func containsKanji(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(Int(scalar.value))
        }
    }

    private func surfaceForms(for word: String) -> [String] {
        var forms = Set([word])
        if word.hasSuffix("む") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "んで", stem + "んだ", stem + "まない", stem + "まず", stem + "まずに", stem + "みます", stem + "めば", stem + "める"])
        }
        if word.hasSuffix("ぶ") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "んで", stem + "んだ", stem + "ばない", stem + "ばず", stem + "ばずに", stem + "びます", stem + "べば", stem + "べる"])
        }
        if word.hasSuffix("ぬ") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "んで", stem + "んだ", stem + "なない", stem + "なず", stem + "なずに", stem + "にます", stem + "ねば"])
        }
        if word.hasSuffix("ぐ") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "いで", stem + "いだ", stem + "がない", stem + "がず", stem + "がずに", stem + "ぎます", stem + "げば", stem + "げる"])
        }
        if word.hasSuffix("く") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "いて", stem + "いた", stem + "かない", stem + "かず", stem + "かずに", stem + "きます", stem + "けば", stem + "ける"])
        }
        if word.hasSuffix("す") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "して", stem + "した", stem + "さない", stem + "さず", stem + "さずに", stem + "します", stem + "せば", stem + "される", stem + "されて", stem + "された"])
        }
        if word.hasSuffix("う") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "って", stem + "った", stem + "わない", stem + "わず", stem + "わずに", stem + "います", stem + "えば", stem + "い", stem + "われる", stem + "われて"])
        }
        if word.hasSuffix("る") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "て", stem + "た", stem + "ない", stem + "ず", stem + "ずに", stem + "ます", stem + "れば", stem + "られる", stem + "られて", stem + "られた", stem + "よう"])
        }
        if word.hasSuffix("い") {
            let stem = String(word.dropLast())
            forms.formUnion([stem + "く", stem + "くない", stem + "かった", stem + "ければ"])
        }
        return Array(forms)
    }
}
