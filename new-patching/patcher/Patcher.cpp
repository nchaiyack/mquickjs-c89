#include <syntax/SyntaxVisitor.h>
#include <sema/Compilation.h>
#include <sema/SemanticModel.h>
#include <symbols/Symbol_ALL.h>

#include <iostream>

using namespace psy;
using namespace C;

class AnalysisVisitor : public SyntaxVisitor
{
public:
    AnalysisVisitor(const SemanticModel* model, const SyntaxTree* tree)
        : SyntaxVisitor(tree)
        , model_(model)
    {}

    const SemanticModel* model_;

    void analyze()
    {
        visit(tree_->rootNode());
    }

    virtual Action visitFunctionDefinition(const FunctionDefinitionSyntax* node) override
    {
        auto decl = model_->functionFor(node);
        std::cout << "  Visiting " << decl << std::endl;

        return Action::Skip;
    }
};

extern "C"
int analyze(const Compilation* compilation)
{
    std::cout << "Analyzing..." << std::endl;
    for (auto tree : compilation->syntaxTrees()) {
        std::cout << " File: " << tree->filePath() << std::endl;
        AnalysisVisitor visitor(compilation->semanticModel(tree), tree);
        visitor.analyze();
    }

    return 0;
}