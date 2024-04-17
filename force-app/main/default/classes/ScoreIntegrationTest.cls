/**
 * @description       : 
 * @author            : dglsmrnh
 * @group             : 
 * @last modified on  : 04-16-2024
 * @last modified by  : dglsmrnh
**/
@IsTest
private class ScoreIntegrationTest {

    @IsTest
    static void testPredict() {
        String testText = 'Este é um texto de teste utilizado para avaliar o desempenho de algoritmos de processamento de linguagem natural. Ele contém uma variedade de palavras, frases e estruturas gramaticais para garantir uma avaliação abrangente. O objetivo é verificar se os algoritmos conseguem lidar adequadamente com diferentes aspectos da língua portuguesa, incluindo pontuação, capitalização e formação de palavras compostas. Além disso, o texto apresenta uma mistura de vocabulário comum e menos comum para desafiar ainda mais os algoritmos. Espera-se que os algoritmos sejam capazes de identificar corretamente o número de palavras, frases e até mesmo sílabas neste texto. Esta avaliação é crucial para garantir a precisão e eficácia dos algoritmos em uma variedade de aplicações práticas, como análise de sentimentos, tradução automática e geração de texto.';
        ScoreIntegration.Response response = ScoreIntegration.predict(testText);

        // Assert the response is not null
        System.assertNotEquals(null, response);

        // // Assert the probability
        // System.assertEquals(76.5, response.probability);

        // // Assert the features
        // System.assertEquals(7.83, response.features.flesch, 0.01);
        // System.assertEquals(56.0, response.features.gulpease, 0.01);
        // System.assertEquals(5.67, response.features.colemanLiau, 0.01);
        // System.assertEquals(7.17, response.features.ari, 0.01);
    }
}
