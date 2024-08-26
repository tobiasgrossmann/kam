import Foundation

struct KamasutraPosition: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    let explanation: String
}

struct KamasutraModel {
    static let positions: [KamasutraPosition] = [
        KamasutraPosition(
            name: NSLocalizedString("balancingact", comment: "A position where balance is key"),
            imageName: "balancingact",
            explanation: NSLocalizedString("balancingact_explanation", comment: "Explanation for balancing act")
        ),
        KamasutraPosition(
            name: NSLocalizedString("chair", comment: "A position resembling sitting on a chair"),
            imageName: "chair",
            explanation: NSLocalizedString("chair_explanation", comment: "Explanation for chair position")
        ),
        KamasutraPosition(
            name: NSLocalizedString("crouchingTiger", comment: "A position inspired by the crouching tiger stance"),
            imageName: "crouchingTiger",
            explanation: NSLocalizedString("crouchingTiger_explanation", comment: "Explanation for crouching tiger position")
        ),
        KamasutraPosition(
            name: NSLocalizedString("doggy", comment: "A position where one partner is on all fours"),
            imageName: "doggy",
            explanation: NSLocalizedString("doggy_explanation", comment: "Explanation for doggy style")
        ),
        KamasutraPosition(
            name: NSLocalizedString("frombehind", comment: "A position where one partner is behind the other"),
            imageName: "frombehind",
            explanation: NSLocalizedString("frombehind_explanation", comment: "Explanation for from behind position")
        ),
        KamasutraPosition(
            name: NSLocalizedString("leopard", comment: "A position mimicking a crouched leopard"),
            imageName: "leopard",
            explanation: NSLocalizedString("leopard_explanation", comment: "Explanation for leopard position")
        ),
        KamasutraPosition(
            name: NSLocalizedString("missionary", comment: "A common face-to-face position"),
            imageName: "missionary",
            explanation: NSLocalizedString("missionary_explanation", comment: "Explanation for missionary position")
        ),
        KamasutraPosition(
            name: NSLocalizedString("mountain", comment: "A position resembling climbing a mountain"),
            imageName: "mountain",
            explanation: NSLocalizedString("mountain_explanation", comment: "Explanation for mountain position")
        ),
        KamasutraPosition(
            name: NSLocalizedString("shoulderholder", comment: "A position where one partner holds the other's shoulders"),
            imageName: "shoulderholder",
            explanation: NSLocalizedString("shoulderholder_explanation", comment: "Explanation for shoulder holder position")
        ),
        KamasutraPosition(
            name: NSLocalizedString("splittingBamboo", comment: "A position where legs are spread wide like bamboo"),
            imageName: "splittingBamboo",
            explanation: NSLocalizedString("splittingBamboo_explanation", comment: "Explanation for splitting bamboo position")
        ),
        KamasutraPosition(
            name: NSLocalizedString("standing", comment: "A position where both partners are standing"),
            imageName: "standing",
            explanation: NSLocalizedString("standing_explanation", comment: "Explanation for standing position")
        ),
        KamasutraPosition(
            name: NSLocalizedString("table", comment: "A position involving a table for support"),
            imageName: "table",
            explanation: NSLocalizedString("table_explanation", comment: "Explanation for table position")
        ),
        KamasutraPosition(
            name: NSLocalizedString("thebasket", comment: "A position where one partner is lifted like a basket"),
            imageName: "thebasket",
            explanation: NSLocalizedString("thebasket_explanation", comment: "Explanation for the basket position")
        ),
        KamasutraPosition(
            name: NSLocalizedString("theclasp", comment: "A position where partners clasp each other closely"),
            imageName: "theclasp",
            explanation: NSLocalizedString("theclasp_explanation", comment: "Explanation for the clasp position")
        ),
        KamasutraPosition(
            name: NSLocalizedString("thesnail", comment: "A position where the body curls like a snail's shell"),
            imageName: "thesnail",
            explanation: NSLocalizedString("thesnail_explanation", comment: "Explanation for the snail position")
        ),
        KamasutraPosition(
            name: NSLocalizedString("thevisitor", comment: "A position symbolizing the arrival of a visitor"),
            imageName: "thevisitor",
            explanation: NSLocalizedString("thevisitor_explanation", comment: "Explanation for the visitor position")
        ),
        KamasutraPosition(
            name: NSLocalizedString("theYCurve", comment: "A position forming a Y-shaped curve"),
            imageName: "theYCurve",
            explanation: NSLocalizedString("theYCurve_explanation", comment: "Explanation for the Y curve position")
        )
    ]
}
