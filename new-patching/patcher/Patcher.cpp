#include <syntax/SyntaxVisitor.h>
#include <syntax/SyntaxDumper.h>
#include <parser/Unparser.h>

#include <sema/Compilation.h>
#include <sema/SemanticModel.h>
#include <symbols/Symbol_ALL.h>

#include <iostream>
#include <sstream>
#include <unordered_map>

using namespace psy;
using namespace C;

// A simple rewriting unparser that demonstrates syntax-directed source rewriting.
// It walks the syntax tree (using SyntaxDumper/Unparser mechanics) and emits
// modified text to an output stream. Example transformations implemented:
// - Identifier macro replacement (very rudimentary, for demonstration)
// - Skipping GNU asm statements entirely
class RewritingUnparser : public Unparser
{
public:
    using Unparser::Unparser;

    void defineMacro(std::string name, std::string value)
    {
        macros_[std::move(name)] = std::move(value);
    }

protected:
    // Token-level hook: replace identifiers via a tiny macro table,
    // otherwise defer to default Unparser formatting.
    void terminal(const SyntaxToken& tk, const SyntaxNode* node) override
    {
        // Replace identifiers if present in macro map.
        if (tk.kind() == SyntaxKind::IdentifierToken) {
            auto it = macros_.find(tk.valueText_c_str());
            if (it != macros_.end()) {
                *os_ << it->second;
                // mimic Unparser spacing/newline behavior
                if (shouldLineBreakAfter(tk))
                    *os_ << "\n";
                else
                    *os_ << ' ';
                return;
            }
        }

        // Default Unparser behavior
        Unparser::terminal(tk, node);
    }

    // Node-level hook: drop certain statement kinds from output entirely.
    Action visitExtGNU_AsmStatement(const ExtGNU_AsmStatementSyntax*) override
    {
        // Skip emitting this node or any of its children.
        return Action::Skip;
    }

private:
    static bool shouldLineBreakAfter(const SyntaxToken& tk)
    {
        return tk.kind() == SyntaxKind::CloseBraceToken
            || tk.kind() == SyntaxKind::OpenBraceToken
            || tk.kind() == SyntaxKind::SemicolonToken;
    }

    std::unordered_map<std::string, std::string> macros_;
};

extern "C"
int analyze(const Compilation* compilation)
{
    std::cerr << "Analyzing..." << std::endl;
    for (auto tree : compilation->syntaxTrees()) {
        std::cerr << " File: " << tree->filePath() << std::endl;
        // Demonstrate a syntax-directed transformation followed by unparsing.
        // Here we apply trivial macro replacements and remove GNU asm statements.
        RewritingUnparser rw(tree);
        // Example macro definitions (tune/extend as needed):
        // rw.defineMacro("inline", "/* inline */");
        // rw.defineMacro("restrict", "/* restrict */");

        std::ostringstream oss;
        rw.unparse(tree->rootNode(), oss);

        // Output the transformed unit to stdout (could be redirected by the caller).
        std::cout << oss.str() << std::endl;
    }

    return 0;
}